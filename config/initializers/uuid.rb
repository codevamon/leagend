require 'active_record/connection_adapters/sqlite3_adapter'

module ActiveRecord
  module ConnectionAdapters
    class SQLite3Adapter
      NATIVE_DATABASE_TYPES[:uuid] = { name: 'varchar', limit: 36 }
    end
  end
end 