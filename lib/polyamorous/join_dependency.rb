module Polyamorous
  module JoinDependencyExtensions

    def self.included(base)
      base.class_eval do
        alias_method_chain :build, :polymorphism
        alias_method_chain :graft, :polymorphism
      end
    end

    def graft_with_polymorphism(*associations)
      associations.each do |association|
        unless join_associations.detect { |a| association == a }
          if association.reflection.options[:polymorphic]
            build(Join.new(association.reflection.name,
                           association.join_type,
                           association.reflection.klass),
                  association.find_parent_in(self) || join_base,
                  association.join_type)
          else
            build(association.reflection.name,
                  association.find_parent_in(self) || join_base,
                  association.join_type)
          end
        end
      end
      self
    end

    def _join_parts
      @join_parts
    end

    def build_with_polymorphism(associations, parent, join_type)
      case associations
      when Join
        reflection = parent.reflections[associations.name] or
          raise ::ActiveRecord::ConfigurationError,
            "Association named '#{ associations.name }' was not found on #{
              parent.base_klass.name }; perhaps you misspelled it?"
        unless join_association = find_join_association_respecting_polymorphism(
          reflection, parent, associations.klass
          )
          @reflections << reflection
          join_association = build_join_association_respecting_polymorphism(
            reflection, parent, join_type, associations.klass
            )
          _join_parts << join_association
          cache_joined_association(join_association)
        end
        join_association
      else
        build_without_polymorphism(associations, parent, join_type)
      end
    end

    def find_join_association_respecting_polymorphism(reflection, parent,
      klass)
      if association = find_join_association(reflection, parent)
        unless reflection.options[:polymorphic]
          association
        else
          association if association.base_klass == klass
        end
      end
    end

    def build_join_association_respecting_polymorphism(reflection, parent,
      join_type, klass)
      if reflection.options[:polymorphic] && klass
        JoinAssociation.new(reflection, self, parent, join_type, klass)
      else
        JoinAssociation.new(reflection, self, parent, join_type)
      end
    end

  end
end