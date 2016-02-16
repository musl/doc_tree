#!/usr/bin/env ruby

require 'pathname'

require 'graphviz'
require 'sequel'

module Graph

	Sequel.extension :pg_json
	Sequel.extension :pg_json_ops

	DB_URI = 'postgresql://graph@localhost/db01'
	DB = Sequel.connect( DB_URI )

	class Node < Sequel::Model

		plugin :schema
		plugin :rcte_tree
		plugin :json_serializer

		set_schema do
			serial  :id, primary_key: true
			integer :parent_id
			jsonb   :doc, default: Sequel.pg_jsonb( {} )

			index :parent_id, unique: false
			index :doc, unique: false, type: Sequel.lit( 'gin' )
		end

		create_table!

		def pp
			puts JSON.pretty_generate( self )
		end

	end

	def self.export( path )
		json = JSON.pretty_generate( Node.all )
		File.write( path, json )
	end

	def self.import( path )
		json = File.read( path )
		nodes = JSON.parse( json )

		unless nodes.is_a? Array
			raise 'The import file must contain an array of nodes.'
		end

		DB.transaction do
			Node.unrestrict_primary_key
			nodes.each do |node|
				begin
					node['doc'] = Sequel.pg_jsonb( node['doc'] )
					Node.create( node )
				rescue => e
					puts e.message
					puts e.backtrace
					raise Sequel::Rollback
				end
			end
			Node.restrict_primary_key
		end
	end

	# Until I figure out more about the graphviz api, it'd probably be
	# best not to render huge graphs...
	#
	def self.render( path, root_id = 0 )
		root = Node[root_id]
		set = [root, root.descendants].flatten.compact
		h = {}
		g = GraphViz.new( :G, :type => :digraph )

		set.each do |node|
			h[node] = g.add_nodes( node.id.to_s )
			node.children.each do |child|
				h[child] ||= g.add_nodes( child.id.to_s )
				g.add_edges( h[node], h[child] )
			end
		end

		g.output( :png => path )
	end

end

if $0 == __FILE__
	include Graph

	path = Pathname( ARGV.shift.to_s )
	if path.file? and path.readable?
		Graph.import( path )
	end

	require 'pry'; binding.pry
end

