require 'spec_helper'

module Polyamorous
  describe JoinAssociation do
    let(:join_dependency) { new_join_dependency Note, {} }
    let(:parent) { join_dependency.join_base }
    let(:reflection) { Note.reflect_on_association(:notable) }
    let(:join_association) {
      JoinAssociation.new(reflection, join_dependency, parent, Article)
    }
    subject {
      join_dependency.build_join_association_respecting_polymorphism(
        reflection, parent, Arel::InnerJoin, Person
      )
    }

    it 'respects polymorphism on equality test' do
      subject.should eq(
        join_dependency.build_join_association_respecting_polymorphism(
          reflection, parent, Arel::InnerJoin, Person
        )
      )
      subject.should_not eq(
        join_dependency.build_join_association_respecting_polymorphism(
          reflection, parent, Arel::InnerJoin, Article
        )
      )
      subject.should_not eq(
        join_dependency.build_join_association_respecting_polymorphism(
          reflection, parent, Arel::OuterJoin, Article
        )
      )
    end

    it 'leaves the orginal reflection intact for thread safety' do
      reflection.instance_variable_set(:@klass, Article)
      join_association.swapping_reflection_klass(reflection, Person
      ) do |new_reflection|
        new_reflection.options.should_not equal reflection.options
        new_reflection.options.should_not have_key(:polymorphic)
        new_reflection.klass.should == Person
        reflection.klass.should == Article
      end
    end

    it 'sets the polmorphic option to true after initializing' do
      join_association.options[:polymorphic].should be_true
    end
  end
end
