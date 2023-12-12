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

class Report::Walker
  attr_accessor :query, :header_stack

  def initialize(query)
    @query = query
  end

  def for_row(&)
    access_block(:row, &)
  end

  def for_final_row(&)
    access_block(:final_row, &) || access_block(:row)
  end

  def for_cell(&)
    access_block(:cell, &)
  end

  def for_empty_cell(&)
    access_block(:empty_cell, &) || access_block(:cell)
  end

  def access_block(name, &block)
    @blocks ||= {}
    @blocks[name] = block if block
    @blocks[name]
  end

  def walk_cell(cell)
    cell ? for_cell[cell] : for_empty_cell[nil]
  end

  def headers(result = nil, &)
    @header_stack = []
    result ||= query.column_first
    sort result
    last_level = -1
    num_in_col = 0
    level_size = 1
    sublevel   = 0
    result.recursive_each_with_level(0, false) do |level, result|
      break if result.final_column?

      if first_in_col = (last_level < level)
        list        = []
        last_level  = level
        num_in_col  = 0
        level_size  = sublevel
        sublevel    = 0
        @header_stack << list
      end
      num_in_col  += 1
      sublevel    += result.size
      last_in_col  = (num_in_col >= level_size)
      @header_stack.last << [result, first_in_col, last_in_col]
      yield(result, level == 0, first_in_col, last_in_col) if block_given?
    end
  end

  def reverse_headers
    fail 'call header first' unless @header_stack

    first = true
    @header_stack.reverse_each do |list|
      list.each do |result, first_in_col, last_in_col|
        yield(result, first, first_in_col, last_in_col)
      end
      first = false
    end
  end

  def headers_empty?
    fail 'call header first' unless @header_stack

    @header_stack.empty?
  end

  def sort_keys
    @sort_keys ||= query.chain.filter_map { |c| c.group_fields.map(&:to_s) if c.group_by? }.flatten
  end

  def sort(result)
    result.set_key sort_keys
    result.sort!
  end

  def body(result = nil, &)
    return [*body(result)].each(&) if block_given?

    result ||= query.result.tap { |r| sort(r) }
    if result.row?
      if result.final_row?
        subresults = query.table.with_gaps_for(:column, result).map(&method(:walk_cell))
        for_final_row.call result, subresults
      else
        subresults = result.map { |r| body(r) }
        for_row.call result, subresults
      end
    else
      # you only get here if no rows are defined
      result.each_direct_result.map(&method(:walk_cell))
    end
  end
end
