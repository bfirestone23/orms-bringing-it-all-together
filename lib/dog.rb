require 'pry'
class Dog
    attr_accessor :id, :name, :breed

    def initialize(name:, breed:, id: nil)
        @name = name
        @breed = breed 
        @id = id
    end

    def self.create_table
        sql = <<-SQL
            CREATE TABLE IF NOT EXISTS dogs (
                id INTEGER PRIMARY KEY,
                name TEXT,
                breed TEXT
            )
        SQL

        DB[:conn].execute(sql)
    end

    def self.drop_table 
        DB[:conn].execute("DROP TABLE dogs")
    end

    def save
        if self.id
            self.update
        else
            sql = <<-SQL
                INSERT INTO dogs (name, breed)
                VALUES (?, ?)
            SQL

            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
        end
        self
    end

    def update
        sql = <<-SQL
        UPDATE dogs 
        SET name = ?, breed = ? 
        WHERE id = ?
        SQL

        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end

    def self.create(hash)
        name = hash[:name]
        breed = hash[:breed]
        new_dog = Dog.new(name: name, breed: breed)
        new_dog.save
        new_dog
    end

    def self.new_from_db(array)
        id = array[0]
        name = array[1]
        breed = array[2]
        new_dog = Dog.new(name: name, breed: breed, id: id)
        new_dog
    end

    def self.find_by_id(id)
        sql = <<-SQL
            SELECT *
            FROM dogs
            WHERE id = ?
            LIMIT 1
        SQL

        DB[:conn].execute(sql, id).map do |row|
            self.new_from_db(row)
        end.first
    end

    def self.find_by_name(name)
        sql = <<-SQL
            SELECT *
            FROM dogs
            WHERE name = ?
            LIMIT 1
        SQL

        DB[:conn].execute(sql, name).map do |row|
            self.new_from_db(row)
        end.first
    end

    def self.find_or_create_by(name:, breed:)
        dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed = ?", name, breed)
        if dog.empty? 
            dog = self.create(name: name, breed: breed)
        else
            dog_data = dog[0]
            dog = Dog.new(name: dog_data[1], breed: dog_data[2], id: dog_data[0])
        end
        dog
    end


end