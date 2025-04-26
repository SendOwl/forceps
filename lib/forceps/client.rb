module Forceps
  class Client
    attr_reader :options

    def configure(options={})
      @options = options.merge(default_options)
      @models_without_table = []
      @models_with_table = []

      declare_remote_model_classes
      make_associations_reference_remote_classes

      logger.debug "Classes handled by Forceps: #{@models_with_table.collect(&:name).inspect}"
    end

    private

    def logger
      Forceps.logger
    end

    def default_options
      {}
    end

    def model_classes
      @model_classes ||= filtered_model_classes
    end

    def filtered_model_classes
      (ActiveRecord::Base.descendants - model_classes_to_exclude).reject do |klass|
        klass.name.start_with?('HABTM_')
      end
    end

    def model_classes_to_exclude
      if defined?(ActiveRecord::SchemaMigration)
        [ActiveRecord::SchemaMigration]
      else
        []
      end
    end

    def declare_remote_model_classes
      return if @remote_classes_defined
      model_classes.each { |remote_class| declare_remote_model_class(remote_class) }
      @remote_classes_defined = true
    end

    def declare_remote_model_class(klass)
      full_class_name = klass.name
      remote_class_name = full_class_name.demodulize
      
      remote_class = Class.new(klass) do
        self.table_name = klass.table_name
        
        # Give the class a proper name in the Forceps::Remote namespace
        def self.name
          "Forceps::Remote::#{superclass.name.demodulize}"
        end

        include Forceps::ActsAsCopyableModel
        establish_connection :remote

        def self.finder_needs_type_condition?
          true
        end
      end

      Forceps::Remote.const_set(remote_class_name, remote_class)
      @models_with_table << klass
    end

    def make_associations_reference_remote_classes
      @models_with_table.each do |local_class|
        make_associations_reference_remote_classes_for(local_class)
      end
    end

    def make_associations_reference_remote_classes_for(model_class)
      model_class.reflect_on_all_associations.each do |association|
        reference_remote_class(model_class, association)
      end
    end

    def reference_remote_class(model_class, association)
      if association.options[:polymorphic]
        reference_remote_class_in_polymorphic_association(association, model_class)
      else
        reference_remote_class_in_normal_association(association, model_class)
      end
    end

    def reference_remote_class_in_polymorphic_association(association, remote_model_class)
      # No need to do anything. Polymorphic associations don't specify the target class.
    end

    def reference_remote_class_in_normal_association(association, remote_model_class)
      related_local_class = association.klass
      related_remote_class = Forceps::Remote.const_get(related_local_class.name.demodulize)

      if association.is_a?(ActiveRecord::Reflection::ThroughReflection)
        reference_remote_class_in_through_association(association, remote_model_class, related_remote_class)
      else
        reference_remote_class_in_direct_association(association, remote_model_class, related_remote_class)
      end
    end

    def reference_remote_class_in_through_association(association, remote_model_class, related_remote_class)
      through_association = remote_model_class.reflect_on_all_associations.find do |a|
        a.name == association.through_reflection.name
      end

      through_remote_class = Forceps::Remote.const_get(through_association.klass.name.demodulize)

      remote_model_class.has_many(
        association.name,
        through: through_association.name,
        source: association.source_reflection.name,
        class_name: related_remote_class.name
      )
    end

    def reference_remote_class_in_direct_association(association, remote_model_class, related_remote_class)
      options = association.options.dup
      options[:class_name] = related_remote_class.name

      remote_model_class.send(
        association.macro,
        association.name,
        **options
      )
    end
  end
end
