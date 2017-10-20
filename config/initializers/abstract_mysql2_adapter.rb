=begin
  Yuck, hate to do this, but older mysql2 gems set primary key to NULL,
  which is not acceptable for more modern mysql servers.
=end
class ActiveRecord::ConnectionAdapters::Mysql2Adapter
  NATIVE_DATABASE_TYPES[:primary_key] = "int(11) auto_increment PRIMARY KEY"
end
