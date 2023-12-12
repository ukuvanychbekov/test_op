#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Report::SqlStatement
  class Union
    attr_accessor :first, :second, :as

    def initialize(first, second, as = nil)
      @first = first
      @second = second
      @as = as
    end

    def to_s
      "((\n#{first.gsub("\n", "\n\t")}\n) UNION (\n" \
        "#{second.gsub("\n", "\n\t")}\n))#{" AS #{as}" if as}\n"
    end

    def each_subselect
      yield first
      yield second
    end

    def gsub(...)
      to_s.gsub(...)
    end
  end

  include Report::QueryUtils

  ##
  # Describes the query. This may be used in a sql-comment later.
  attr_accessor :desc

  ##
  # Generates new SqlStatement.
  #
  # @param [String, #to_s] table Table name (or subselect) for from part.
  def initialize(table, desc = '')
    self.desc = desc
    from table
  end

  ##
  # Creates a uninon of the caller and the callee.
  #
  # @param [Report::SqlStatement] other Second part of the union
  # @return [String] The sql query.
  def union(other, as = nil)
    Union.new(self, other, as)
  end

  ##
  # Adds sum(..) part to select.
  #
  # @param [#to_s] field Name of the field to aggregate on
  # @param [#to_s] name Name of the result (defaults to sum)
  def sum(field, name = :sum, type = :sum)
    @sql = nil
    return sum({ name => field }, nil, type) unless field.respond_to? :to_hash

    field.each { |k, v| field[k] = "#{type}(#{v})" }
    select field
  end

  ##
  # Adds count(..) part to select.
  #
  # @param [#to_s] field Name of the field to aggregate on (defaults to *)
  # @param [#to_s] name Name of the result (defaults to sum)
  def count(field = '*', name = :count)
    sum field, name, :count
  end

  ##
  # Generates the SQL query.
  # Code looks ugly in exchange for pretty output (so one does unterstand those).
  #
  # @return [String] The query
  def to_s
    # FIXME I'm ugly
    @sql ||= begin
      sql = "\n-- BEGIN #{desc}\n" \
            "-- DB: #{ActiveRecord::Base.connection.current_database}\n" \
            "SELECT\n#{select.map { |e| "\t#{e}" }.join ",\n"}" \
            "\nFROM\n\t#{from.gsub("\n", "\n\t")}" \
            "\n\t#{joins.map { |e| e.gsub("\n", "\n\t") }.join "\n\t"}" \
            "\nWHERE #{where.join ' AND '}\n"
      sql << "GROUP BY #{group_by.join ', '}\nORDER BY #{group_by.join ', '}\n" if group_by?
      sql << "-- END #{desc}\n"
      sql # << " LIMIT 100"
    end
  end

  ##
  # @overload from
  #   Reads the from part.
  #   @return [#to_s] From part
  # @overload from(table)
  #   Sets the from part.
  #   @param [#to_s] table
  #   @param [#to_s] From part
  def from(table = nil)
    return @from unless table

    @sql = nil
    @from = table
  end

  ##
  # Where conditions. Will be joined together by AND.
  #
  # @overload where
  #   Reads the where part
  #   @return [Array<#to_s>] Where clauses
  # @overload where(fields)
  #   Adds condition to where clause
  #   @param [Array, Hash, String] fields Parameters passed to sanitize_sql_for_conditions.
  # @see Report::QueryUtils#sanitize_sql_for_conditions
  def where(fields = nil)
    @where ||= ['1=1']
    unless fields.nil?
      @where << sanitize_sql_for_conditions(fields)
      @sql = nil
    end
    @where
  end

  ##
  # @return [Array<String>] List of table joins
  def joins
    (@joins ||= []).tap(&:uniq!)
  end

  ##
  # Adds an "left outer join" (guessing field names) to #joins.
  #
  # @overload join(name)
  #   @param [Symbol, String] name Singular table name to join with, will join plural from on table.id = table_id
  # @overload join(model)
  #   @param [#table_name, #model_name] model ActiveRecord model to join with
  # @overload join(hash)
  #   @param [Hash<#to_s => #to_s>] hash Key is singular table name to join with, value is field to join on
  # @overload join(*list)
  #   @param [Array<String,Symbol,Array>] list Will generate join entries (according to guessings described above)
  # @see #joins
  def join(*list)
    @sql = nil
    join_syntax = 'LEFT OUTER JOIN %1$s ON %1$s.id = %2$s_id'
    list.each do |e|
      case e
      when Class          then joins << (join_syntax % [table_name_for(e), e.lookup_ancestors.last.model_name.to_s.underscore])
      when / /            then joins << e
      when Symbol, String then joins << (join_syntax % [table_name_for(e), e])
      when Hash           then e.each { |k, v| joins << (join_syntax % [table_name_for(k), field_name_for(v)]) }
      when Array          then join(*e)
      else raise ArgumentError, "cannot join #{e.inspect}"
      end
    end
  end

  def default_select(value = nil)
    @default_select = value if value
    @default_select ||= ['*']
  end

  ##
  # @overload select
  #   @return [Array<String>] All fields/statements for select part
  #
  # @overload select(*fields)
  #   Adds fields to select query.
  #   @example
  #     SqlStatement.new.select(some_sql_statement) # [some_sql_statement.to_s]
  #     SqlStatement.new.select("sum(foo)")         # ["sum(foo)"]
  #     SqlStatement.new.select(:a).select(:b)      # ["a", "b"]
  #     SqlStatement.new.select(:bar => :foo)       # ["foo as bar"]
  #     SqlStatement.new.select(:bar => nil)        # ["NULL as bar"]
  #   @param [Array, Hash, String, Symbol, SqlStatement] fields Fields to add to select part
  #   @return [Array<String>] All fields/statements for select part
  def select(*fields)
    return(@select || default_select) if fields.empty?

    (@select ||= []).tap do
      @sql = nil
      fields.reject { |f| never_select.include? f }.each do |f|
        case f
        when Array
          if f.size == 2 and f.first.respond_to? :table_name then select field_name_for(f)
          else select(*f)
          end
        when Hash then select f.map { |k, v| "#{field_name_for v} as #{field_name_for k}" }
        when String, Symbol then @select << field_name_for(f)
        when engine::SqlStatement then @select << f.to_s
        else raise ArgumentError, "cannot handle #{f.inspect}"
        end
      end
      # when doing a union in sql, both subselects must have the same order.
      # by sorting here we never ever have to worry about this again, sucker!
      @select = @select.uniq.sort_by { |x| x.split(' as ').last }
    end
  end

  def unselect(*fields)
    @sql = nil
    @select = @select.reject do |field|
      fields.find { |f| f == field }
    end
  end

  def never_select(*fields)
    (@never_select ||= []).tap do
      unless fields.empty?
        @never_select += fields
        unselect *fields
      end
    end
  end

  ##
  # Return the names which have been bound through select statements
  # @return [Array<String>] All fields for select part
  def selects
    @select.map { |s| s.split(' as ').last }
  end

  ##
  # @overload group_by
  #   @return [Array<String>] All fields/statements for group by part
  #
  # @overload group(*fields)
  #   Adds fields to group by query
  #   @param [Array, String, Symbol] fields Fields to add
  def group_by(*fields)
    @sql = nil unless fields.empty?
    (@group_by ||= []).tap do
      fields.reject { |f| never_group_by.include? f }.each do |e|
        if e.is_a? Array and (e.size != 2 or !e.first.respond_to? :table_name)
          group_by(*e)
        else
          @group_by << field_name_for(e)
        end
      end
      @group_by.uniq!
    end
  end

  def group_not_by(*fields)
    @sql = nil
    @group_by = @group_by.reject do |field|
      fields.find { |f| f == field }
    end
  end

  def never_group_by(*fields)
    (@never_group_by ||= []).tap do
      unless fields.empty?
        @never_group_by += fields
        group_not_by *fields
      end
    end
  end

  ##
  # @return [TrueClass, FalseClass] Whether or not to add a group by part.
  def group_by?
    !group_by.empty?
  end

  def inspect
    "#<SqlStatement: #{to_s.inspect}>"
  end

  def gsub(...)
    to_s.gsub(...)
  end
end
