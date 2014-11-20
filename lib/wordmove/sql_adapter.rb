module Wordmove
  class SqlAdapter
    attr_reader :sql_path, :source_config, :dest_config

    def initialize(sql_path, source_config, dest_config)
      @sql_path = sql_path
      @source_config = source_config
      @dest_config = dest_config
    end

    def sql_content
      @sql_content ||= File.open(sql_path).read
    end

    def adapt!
      replace_vhost!
      replace_wordpress_path!
    end

    # private

    def replace_vhost!
      source_vhost = source_config[:vhost]
      dest_vhost = dest_config[:vhost]
      replace_field!(source_vhost, dest_vhost)
    end

    def replace_wordpress_path!
      source_path = source_config[:wordpress_absolute_path] || source_config[:wordpress_path]
      dest_path = dest_config[:wordpress_absolute_path] || dest_config[:wordpress_path]
      replace_field!(source_path, dest_path)
    end

    def replace_field!(source_field, dest_field)
      if source_field && dest_field
        serialized_replace!(source_field, dest_field)
        simple_replace!(source_field, dest_field)
      end
    end

    def serialized_replace!(source_field, dest_field)
      length_delta = source_field.length - dest_field.length

      foreach_sql_line do |line|
        line.gsub!(/s:(\d+):([\\]*['"])(.*?)\2;/) do |match|
          length = $1.to_i
          delimiter = $2
          string = $3

          string.gsub!(/#{Regexp.escape(source_field)}/) do |match|
            length -= length_delta
            dest_field
          end
          %(s:#{length}:#{delimiter}#{string}#{delimiter};)
        end
      end
    end

    def simple_replace!(source_field, dest_field)
      foreach_sql_line do |line|
        line.gsub!(source_field, dest_field)
      end
    end

    def foreach_sql_line
      File.open("#{sql_path}.tmp", 'w') do |temp_output|
        File.open(sql_path, 'r') do |sql_file|
          while line = sql_file.gets
            result = yield line
            temp_output.write(result)
          end
        end
      end
      File.rename("#{sql_path}.tmp", sql_path)
    end

  end
end
