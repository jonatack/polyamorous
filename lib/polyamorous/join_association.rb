module Polyamorous
  module JoinAssociationExtensions

    def self.included(base)
      base.class_eval do
        alias_method_chain :initialize, :polymorphism
        alias_method :equality_without_polymorphism, :==
        alias_method :==, :equality_with_polymorphism
        alias_method_chain :build_constraint, :polymorphism
      end
    end

    def initialize_with_polymorphism(reflection, join_dependency, parent = nil, polymorphic_class = nil)
      if polymorphic_class && ::ActiveRecord::Base > polymorphic_class
        swapping_reflection_klass(reflection, polymorphic_class) do |reflection|
          initialize_without_polymorphism(reflection, join_dependency, parent)
          self.reflection.options[:polymorphic] = true
        end
      else
        initialize_without_polymorphism(reflection, join_dependency, parent)
      end
    end

    def swapping_reflection_klass(reflection, klass)
      new_reflection = reflection.clone
      new_reflection.instance_variable_set(:@options, reflection.options.clone)
      new_reflection.options.delete(:polymorphic)
      new_reflection.instance_variable_set(:@klass, klass)
      yield new_reflection
    end

    def equality_with_polymorphism(other)
      equality_without_polymorphism(other) && base_klass == other.base_klass
    end

    def build_constraint_with_polymorphism(klass, table, key, foreign_table, foreign_key)
      if @reflection.options[:polymorphic]
        build_constraint_without_polymorphism(klass, table, key, foreign_table, foreign_key).
        and(foreign_table[@reflection.foreign_type].
        eq(klass.name)
        )
      else
        build_constraint_without_polymorphism(klass, table, key, foreign_table, foreign_key)
      end
    end

  end
end