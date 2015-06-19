module Persistable
  module ClassMethods
    def public_attributes
      attributes.keys.reject{|k| k == :id}
    end

    def db
      DB[:conn]
    end

    def table_name
      "#{self.to_s.downcase}s"
    end

    def create_table
      create_statement = attributes.collect{|k, v|
        "#{k} #{v}"}.join(", ")

        sql = <<-SQL
          CREATE TABLE IF NOT EXISTS #{self.table_name} (#{create_statement});
        SQL

      self.db.execute(sql)
    end

    def drop_table
      sql = <<-SQL
        DROP TABLE #{self.table_name}
      SQL
      self.db.execute(sql)
    end

    def new_from_db(row)
      if !row.flatten.compact.empty?
        self.new.tap { |s|
          self.attributes.keys.each.with_index(0) { |attribute, i|
            s.send("#{attribute}=", row[i])
          }
        }
      end
    end

    def find_by_name(name)
      sql = <<-SQL
        SELECT * FROM #{self.table_name} WHERE name = ? LIMIT 1
      SQL
      row = self.db.execute(sql, name).flatten
      self.new_from_db(row)
    end
  end

  module InstanceMethods
    def attribute_values
      self.class.public_attributes.collect{|k| self.send(k)}
    end

    def persisted?
      !!self.id
    end

    def save
      if !frozen?
        persisted? ? update : insert
      end
    end

    def insert
      sql_for_insert = self.class.public_attributes.join(",")
      question_marks = self.class.public_attributes.collect{"?"}.join(",")

      sql = <<-SQL
        INSERT INTO #{self.class.table_name} (#{sql_for_insert}) VALUES
        (#{question_marks})
      SQL
      self.class.db.execute(sql, *attribute_values)

      sql = <<-SQL
        SELECT last_insert_rowid() fROM #{self.class.table_name}
      SQL
      @id = self.class.db.execute(sql)[0][0]
    end

    def update
      sql_for_update = self.class.public_attributes.collect{|k| "#{k} = ?"}.join(",")

      sql = <<-SQL
        UPDATE #{self.class.table_name} SET #{sql_for_update} WHERE id = ?
      SQL

      self.class.db.execute(sql, *attribute_values, self.id)
    end
  end
end
