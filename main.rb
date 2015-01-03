# -*- encoding: utf-8 -*-
require "neo4j-core"

# Session
session = Neo4j::Session.open(:server_db)

# Label/Index
l1 = "北斗神拳"
l2 = "伝承者"
labels = [l1, l2]
i1 = Neo4j::Label.create(l1)
i1.create_index(:name)
i2 = Neo4j::Label.create(l2)
i2.create_index(:name)

Neo4j::Transaction.run do

  # Node削除
  all_nodes = Neo4j::Session.query("MATCH (n) RETURN n")
  all_nodes.each{|n|
    n.first.delete
  }

  # Node
  #
  nkt = Neo4j::Node.create({name: "霞鉄心"}, *labels)
  nkk = Neo4j::Node.create({name: "霞拳志郎", hero: true}, *labels)
  # プロパティを一つ設定。ラベルを複数設定。
  nr = Neo4j::Node.create({name: "リュウケン"}, l1, l2)
  # プロパティを後から設定
  nk = Neo4j::Node.create({name: "コウリュウ"}, l1)
  n1 = Neo4j::Node.create({name: "ラオウ"}, l1)
  n1[:hero] = false
  # 複数のキーを持つ連想配列でプロパティを設定。ラベルは一つだけ設定。
  props_n2 = {
    name: "トキ",
    hero: false,
  }
  n2 = Neo4j::Node.create(props_n2, l1)
  n3 = Neo4j::Node.create({name: "ジャギ", hero: false}, l1)
  # ラベルを配列展開して設定
  n4 = Neo4j::Node.create({name: "ケンシロウ"}, *labels)
  n4[:hero] = true
  n5 = Neo4j::Node.create({name: "キム"}, l1)

  # Relationship
  nkt.create_rel(:student, nkk, {inherit: true})
  nkk.create_rel(:student, nr, {inherit: true})
  nkk.create_rel(:student, nk)
  nkk.create_rel(:teacher, nkt)
  nk.create_rel(:teacher, nkk)
  # プロパティを後から設定
  rel = nr.create_rel(:student, n1, {order: 1})
  rel[:inherit] = false
  nr.create_rel(:student, n2, {order: 2})
  nr.create_rel(:student, n3, {order: 3})
  nr.create_rel(:teacher, nkk)
  # 複数のキーを持つ連想配列でプロパティを設定
  nr.create_rel(:student, n4, {order: 4, inherit: true})
  nr.create_rel(:student, n5)
  n1.create_rel(:teacher, nr)
  n2.create_rel(:teacher, nr)
  n3.create_rel(:teacher, nr)
  n4.create_rel(:teacher, nr)
  n5.create_rel(:teacher, nr)

  # Nodeの検索
  puts "\nNode idでNodeを検索"
  nk = Neo4j::Node.load(n4.neo_id)
  puts "neo_id:#{nk.neo_id} props:#{nk.props}"

  puts "\nLabel[#{l1}]とnameでNodeを検索"
  nodes = Neo4j::Label.find_nodes(l1, :name, "ジャギ")
  nodes.each{|n|
    puts "neo_id:#{n.neo_id} name:#{n.props[:name]}"
  }

  puts "\nLabel[#{l2}]を指定して全Node検索"
  all_nodes = Neo4j::Label.find_all_nodes(l2)
  all_nodes.each{|n|
    puts "neo_id:#{n.neo_id} name:#{n.props[:name]}"
  }

  puts "\n指定したNodeに接続する全Relationshipを検索"
  nodes = Neo4j::Label.find_nodes(l2, :name, "リュウケン")
  nr = nodes.first
  nodes = nr.rels
  nodes.each{|n|
    puts "neo_id:#{n.neo_id} props:#{n.props}"
  }

  puts "\noutgoingなRelationshipを検索"
  nodes = Neo4j::Label.find_nodes(l2, :name, "リュウケン")
  nr = nodes.first
  rels = nr.rels(dir: :outgoing)
  rels.each{|r|
    puts "neo_id:#{r.neo_id} rel_type:#{r.rel_type} props:#{r.props}"
  }

  puts "\noutgoingなRelationshipの先のNodeを検索"
  nodes = Neo4j::Label.find_nodes(l2, :name, "リュウケン")
  nr = nodes.first
  nodes = nr.nodes(dir: :outgoing)
  nodes.each{|n|
    puts "neo_id:#{n.neo_id} labels:#{n.labels} props:#{n.props}"
  }

  # Queries
  puts "\nRelationshipにinherit=trueをもつパスを検索"
  inherit_path = Neo4j::Session.query("MATCH (s)-[r {inherit:true}]->(g) RETURN s, r, g")
  inherit_path.each{|path|
    path.each{|n|
      puts "neo_id:#{n.neo_id} props:#{n.props}"
    }
  }

  puts "\nパラメータを用いた検索"
  inherit_path = Neo4j::Session.query("MATCH (s)-[r {inherit:{value}}]->(g) RETURN s, r, g", value: true)
  inherit_path.each{|path|
    path.each{|n|
      puts "neo_id:#{n.neo_id} props:#{n.props}"
    }
  }

  puts "\nLabel=伝承者のNodeを検索(return)"
  query = Neo4j::Session.query.match(n: l2)
  res = query.return(:n)
  res.each{|path|
    path.each{|n|
      puts "neo_id:#{n.neo_id} labels:#{n.labels} props:#{n.props}"
    }
  }

  puts "\nLabel=伝承者のNodeのプロパティを列挙"
  query = Neo4j::Session.query.match(n: l2)
  res = query.return(n: [:name])
  res.each{|path|
    path.each{|n|
      puts "name:#{n}"
    }
  }

  puts "\nname=リュウケンのNodeを検索(pluck)"
  arr = query.pluck(:n)
  arr.each{|n|
    puts "neo_id:#{n.neo_id} props:#{n.props}"
  }

end
