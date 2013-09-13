require 'my_test_helper'
require 'alloy/helpers/test/dsl_helpers'
require 'alloy/initializer.rb'

include Alloy::Dsl

# dir_cls = Object.send :remove_const, :Dir
# file_cls = Object.send :remove_const, :File

alloy_model :A_M_FST do
  sig Name
  abstract sig Obj

  sig FolderEntry, {
    name: Name,
    content: Obj
  }

  sig Folder < Obj, {
    entries: (set FolderEntry),
    parent: (lone Folder)
  } {
  }

  sig :File < Obj {
    # Folder.some do |d|
    #   d.entries.content.contains? d
    # end
  }

  one sig Root < Folder {
    #no parent
  }

  lone sig Curr < Folder {
  }

  sig X {
  }
end

# Object.send :const_set, :Dir, dir_cls
# Object.send :const_set, :File, file_cls

class FileSystemTest < Test::Unit::TestCase
  include Alloy::Helpers::Test::DslHelpers
  include SDGUtils::Testing::SmartSetup
  include SDGUtils::Testing::Assertions

  include A_M_FST

  def setup_class
    Alloy.reset
    Alloy.meta.restrict_to(A_M_FST)
    Alloy.initializer.resolve_fields
    Alloy.initializer.init_inv_fields
  end

  def test
    # ans = A_M_ABT.delUndoesAdd
    # puts "#{ans}"
    # puts "-----------"
    # ans = A_M_ABT.delUndoesAdd_alloy
    # puts "#{ans}"
    puts Alloy.meta.to_als
  end
end
