DocTree
=======

This needs the following gems:

	sequel
	pg
    pry
	ruby-graphviz

To render an image of the test data:

    ./pg_graph import_test.json
	[1] pry(main)> Graph.render( 'test.png' )
	=> nil
	[2] pry(main)>!!!
	# Use your favorite program to view: test.png

This example creates a GIN index on the 'doc' jsonb column.  That means
you'll probably want at least Postgres 9.5.  It also means things like:

    doc = Sequel.pg_jsonb_op( :doc )
    Node.find( doc.has_key?( 'message' ) )
	# SQL: SELECT * FROM "nodes" WHERE ("doc" ? 'message')

... will use the index and hopefully be quite quick.

Quick summary of node management:

	root = Node.create( doc: Sequel.jsonb( { foo: 'bar' ... } )
	root.add_child( doc: Sequel.jsonb( { baz: 'moo' ... } )
	root.descendants
	> [#<Graph::Node @values={:id=>1 :parent_id=>0, :doc={...}}>, ...]

See <http://sequel.jeremyevans.net/rdoc-plugins/classes/Sequel/Plugins/RcteTree.html> for more info on what you can do with the model.

MIT License: <https://opensource.org/licenses/MIT>

