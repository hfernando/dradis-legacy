# Dradis Note objects are associated with a Node. It is possible to create a
# tree structure of Nodes to hierarchically structure the information held
# in the repository.
#
# Each Node has a :parent node and a :label. Nodes can also have many
# Attachment objects associated with them.
#

module Dradis
  module Core
    class Node < ActiveRecord::Base
      self.table_name = 'dradis_nodes'
      module Types
        DEFAULT = 0
        HOST = 1
        METHODOLOGY = 2
        ISSUELIB = 3
      end

      # Virtual attribute:
      #   * Set by the NotesController when modifying a note
      #   * Used by the RevisionObserver to track record changes
      attr_accessor :updated_by

      acts_as_tree

      # -- Relationships --------------------------------------------------------
      has_many :notes, dependent: :destroy
      has_many :evidence, dependent: :destroy


      # -- Callbacks ------------------------------------------------------------
      before_destroy :destroy_attachments
      before_save do |record|
        record.type_id = Types::DEFAULT unless record.type_id
        record.position = 0 unless record.position
      end

      # -- Validations ----------------------------------------------------------
      validates :label, presence: true

      # -- Scopes ---------------------------------------------------------------
      scope :in_tree, -> { where("type_id IN (?)", [Types::DEFAULT, Types::HOST]).where(parent_id: nil) }

      # -- Class Methods --------------------------------------------------------

      # Returns or creates the Node that acts as container for all Issues in a
      # given project
      def self.issue_library
        if (issue_lib = where(type_id: Node::Types::ISSUELIB).limit(1).first)
          issue_lib
        else
          create(label: 'All issues', type_id: Node::Types::ISSUELIB)
        end
      end

      # -- Instance Methods -----------------------------------------------------
      def ancestor_of?(node)
        node && node.ancestors.include?(self)
      end
      # Return all the Attachment objects associated with this Node.
      def attachments
        Attachment.find(:all, conditions: {node_id: self.id})
      end

      private
      # Whenever a node is deleted all the associated attachments have to be
      # deleted too
      def destroy_attachments
        attachments_dir = Attachment.pwd.join(self.id.to_s)
        FileUtils.rm_rf attachments_dir if File.exists?(attachments_dir)
      end
    end
  end
end
