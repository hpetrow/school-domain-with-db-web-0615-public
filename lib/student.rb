class Student
  ATTRIBUTES = {
    :id => "INTEGER PRIMARY KEY AUTOINCREMENT",
    :name => "TEXT",
    :tagline => "TEXT",
    :github => "TEXT",
    :twitter => "TEXT",
    :blog_url => "TEXT",
    :image_url => "TEXT",
    :biography => "TEXT"
  }

  def self.attributes
    ATTRIBUTES
  end

  extend Persistable::ClassMethods
  include Persistable::InstanceMethods

  attr_accessor :id, *self.public_attributes
end
