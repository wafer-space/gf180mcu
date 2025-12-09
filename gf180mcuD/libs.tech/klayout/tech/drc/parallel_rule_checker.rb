require 'thread'
require 'stringio'
require 'io/wait'
require 'tmpdir'

class ParallelRuleChecker
  def initialize(rule_files, rule_binding, logger, num_workers: 4)
    @rule_files = rule_files
    @rule_binding = rule_binding
    @logger = logger
    @num_workers = num_workers + 1 # +1 because master worker does no work
    timestamp = Time.now.strftime("drc_run_%Y_%m_%d_%H_%M_%S__")
    @tmpdir = Dir.mktmpdir(timestamp)
  end

  def run
    _run(@rule_files)
  end

  private
  def merge_databases(db1, db2)
    # Copy metadata from db2 to db1 if db1 is empty
    if db1.description.empty? && !db2.description.empty?
      db1.description = db2.description
    end

    if db1.generator.empty? && !db2.generator.empty?
      db1.generator = db2.generator
    end

    if db1.top_cell_name.empty? && !db2.top_cell_name.empty?
      db1.top_cell_name = db2.top_cell_name
    end

    if db1.original_file.empty? && !db2.original_file.empty?
      db1.original_file = db2.original_file
    end

    category_map = {}
    cell_map = {}

    # Copy cells
    db2.each_cell do |cell2|
      cell1 = db1.cell_by_qname(cell2.qname)
      if cell1.nil?
        cell1 = cell2.variant.empty? ?
          db1.create_cell(cell2.name) :
          db1.create_cell(cell2.name, cell2.variant)
      end
      cell_map[cell2.rdb_id] = cell1
    end

    # Helper to get the full path of a category by traversing up the tree
    get_full_path = lambda do |cat|
      path_parts = []
      current = cat
      while current
        path_parts.unshift(current.name)
        current = current.parent
      end
      path_parts.join('.')
    end

    # Copy categories recursively - preserving actual hierarchy
    copy_category = lambda do |cat2, parent1|
      # Check if category already exists
      if parent1.nil?
        # Top-level category
        cat1 = db1.category_by_path(cat2.name)
        if cat1.nil?
          cat1 = db1.create_category(cat2.name)
        end
      else
        # Sub-category - check within parent
        parent_path = get_full_path.call(parent1)
        full_path = "#{parent_path}.#{cat2.name}"
        cat1 = db1.category_by_path(full_path)
        if cat1.nil?
          cat1 = db1.create_category(parent1, cat2.name)
        end
      end

      # Copy description
      if cat1.description.empty? && !cat2.description.empty?
        cat1.description = cat2.description
      end

      # Store in map using the full path from db2
      full_path2 = get_full_path.call(cat2)
      category_map[cat2.rdb_id] = cat1

      # Recursively copy sub-categories
      cat2.each_sub_category do |sub_cat2|
        copy_category.call(sub_cat2, cat1)
      end
    end

    # Copy all top-level categories
    db2.each_category do |cat2|
      copy_category.call(cat2, nil)
    end

    # Copy items
    db2.each_item do |item2|
      cell1 = cell_map[item2.cell_id]
      cat1 = category_map[item2.category_id]

      if cell1 && cat1
        item1 = db1.create_item(cell1.rdb_id, cat1.rdb_id)

        # Copy values
        item2.each_value { |value| item1.add_value(value) }

        ## Copy tags
        #item2.each_tag { |tag_id| item1.add_tag(tag_id) }
      end
    end

    db1
  end

  def _run(rule_files)
    rule_files = @rule_files
    results = []
    pids = []

    puppets = []
    pipes = @num_workers.times.map { IO.pipe }
    @num_workers.times do |i|
      reader, writer = pipes[i]
      master_to_puppet_r, master_to_puppet_w = IO.pipe
      puppet_to_master_r, puppet_to_master_w = IO.pipe

      pid = fork do
        reader.close
        # Child (puppet)
        chunk_results = []
        master_to_puppet_w.close
        puppet_to_master_r.close

        # Tell master we are ready
        puppet_to_master_w.puts "ready"

        loop do

          # Wait for next task (blocks until master writes something)
          task = master_to_puppet_r.gets
          if task == nil
            sleep(0.01)
            next
          end
          task.chomp!

          break if task == "shutdown"

          @logger.info("Worker #{i}: Processing #{File.basename(task)}")
          begin
            result = execute_rule(task)
            chunk_results << result
          rescue => e
            @logger.info("Worker #{i}: Error processing #{File.basename(task)} : #{e.message}")

            chunk_results << { file: task, error: e.message }
          end
          @logger.info("Worker #{i}: Done processing #{File.basename(task)}")
          # Tell master we are ready
          puppet_to_master_w.puts "ready"

        end
        @logger.info("Worker #{i}: Shutting down")

        # Send results back to parent
        writer.write(Marshal.dump(chunk_results))
        writer.close
        exit
      end

      writer.close
      master_to_puppet_r.close
      puppet_to_master_w.close

      puppets << {
        pid: pid,
        to_puppet: master_to_puppet_w,
        from_puppet: puppet_to_master_r
      }
    end

    # Master loop
    strings_queue = rule_files.dup

    while !strings_queue.empty? || puppets.any?
      # Wait for ready puppets
      ready_pipes = puppets.map { |p| p[:from_puppet] }.select { |r| r.ready? }

      ready_pipes.each do |pipe|
        pipe.gets # remove "ready"
        puppet = puppets.find { |p| p[:from_puppet] == pipe }

        if strings_queue.empty?
          # No more tasks, send shutdown
          puppet[:to_puppet].puts "shutdown"
          puppet[:to_puppet].flush
          puppets.delete(puppet)
        else
          # Send next task
          next_string = strings_queue.shift
          puppet[:to_puppet].puts next_string
          puppet[:to_puppet].flush
        end
      end
    end

    # Collect results from all processes
    pipes.each do |reader, _|
      chunk_results = Marshal.load(reader.read)
      results.concat(chunk_results)
      reader.close
    end

    # Wait for all puppets to finish
    puppets.each do |p|
      Process.wait(p[:pid])
    end

    @logger.info("All workers completed. Total results: #{results.size}")

    aggregated_res = RBA::ReportDatabase.new()
    results.each do | element |
      incoming_rep = RBA::ReportDatabase.new()
      incoming_rep.load(element[:result])
      aggregated_res = merge_databases(aggregated_res, incoming_rep)
    end

    aggregated_res
  end

  def execute_rule(file)
    report_location = File.join(@tmpdir, "#{File.basename(file)}.lyrdb")
    @rule_binding.eval(%(r = report('Report for #{File.basename(file)}', '#{report_location}')))
    rule_code = File.read(file)
    eval(rule_code, @rule_binding, file)

    @rule_binding.local_variable_get(:r).rdb.save(report_location)
    {
      file: File.basename(file),
      result: report_location,
      timestamp: Time.now
    }
  rescue => e
    {
      file: File.basename(file),
      result: "ERROR: #{e.message}",
      timestamp: Time.now
    }
  end

end
