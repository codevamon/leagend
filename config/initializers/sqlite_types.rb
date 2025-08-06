require 'active_record/connection_adapters/sqlite3_adapter'

module ActiveRecord
  module ConnectionAdapters
    class SQLite3Adapter
      NATIVE_DATABASE_TYPES[:uuid] = { name: 'varchar', limit: 36 }
      NATIVE_DATABASE_TYPES[:string] = { name: 'varchar', limit: 255 }
      NATIVE_DATABASE_TYPES[:text] = { name: 'text' }
      NATIVE_DATABASE_TYPES[:integer] = { name: 'integer' }
      NATIVE_DATABASE_TYPES[:float] = { name: 'float' }
      NATIVE_DATABASE_TYPES[:decimal] = { name: 'decimal' }
      NATIVE_DATABASE_TYPES[:datetime] = { name: 'datetime' }
      NATIVE_DATABASE_TYPES[:time] = { name: 'time' }
      NATIVE_DATABASE_TYPES[:date] = { name: 'date' }
      NATIVE_DATABASE_TYPES[:binary] = { name: 'blob' }
      NATIVE_DATABASE_TYPES[:boolean] = { name: 'boolean' }
    end
  end
end 