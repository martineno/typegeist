class Node
    def initialize(graph)
        @graph = graph
        graph.nodes << self
    end

    attr_reader :graph
    attr_accessor :name
end

class Edge
    def initialize(graph)
        @graph = graph
        graph.edges << self
    end

    attr_reader :graph
    attr_accessor :from, :to
    attr_accessor :weight
end

class Digraph
    def initialize
        self.nodes = []
        self.edges = []
    end

    def node(name)
        idx = self.nodes.index { |node| node.name == name }
        return idx.nil? ? nil : self.nodes[idx]
    end

    def edge(from, to)
        idx = self.edges.index { |edge| edge.from == from && edge.to == to }
        return idx.nil? ? nil : self.edges[idx]
    end

    def out_edges(from)
        return self.edges.select { |edge| edge.from == from }
    end

    def in_edges(to)
        return self.edges.select { |edge| edge.to == to }
    end

    def delete_node(node)
        if node.graph == self then
            self.nodes.delete(node)
        end
    end

    def delete_edge(edge)
        if edge.graph == self then
            self.edges.delete(edge)
        end
    end

    attr_accessor :nodes, :edges
end

# typegeist infographic idea #1: a font family dominator graph
#
# say that you have a CSS font-family fallback of A, B, C, D.
# we say that A dominates B and C, and C and D are dominated by B.
#
# draw a digraph where the nodes represent font families, and the edges
# represent dominance relationships.  weight each edge with some metric
# correlated with the designer's desire to use the font family in their designs.
#
# after all nodes and edges have been drawn, for all pairs of fonts A and B,
# remove the edge [A, B] or [B, A] with lower weight.
#
# what do the remaining edges tell us about designer preference?

def node_for_font_family(g, name)
    node = g.node(name)

    if node.nil? then
        node = Node.new(g)
        node.name = name
    end

    return node
end

def dominate(g, dom, sub, weight)
    edge = g.edge(dom, sub)

    if edge.nil? then
        edge = Edge.new(g)
        edge.from = dom
        edge.to = sub
        edge.weight = 0
    end

    edge.weight += weight

    return edge
end

def dominator_graph(dbUri)
    require 'sequel'
    db = Sequel.connect(dbUri)
    require '../model/scrape'
    init_model(db)

    dg = Digraph.new

    Style.each do |style|
        # parse fallback
        families = style.font_family.split(',')
        dominators = []

        # for each fallback element:
        families.each do |family|
            # normalize font family name: strip space, lowercase, and remove quotes
            family = family.strip.downcase
            if /^\'(.*)\'$/.match(family) then
                family = $1
            end

            # get node
            node = node_for_font_family(dg, family)

            # add dominance relationships
            dominators.each { |dom| dominate(dg, dom, node, style.characters) }

            # add to list of dominators
            dominators << node
        end
    end

    return dg
end

def reduced_dominator_graph(dbUri)
    domgraph = dominator_graph(dbUri)

    domgraph.edges.each do |edge|
        if edge.from == edge.to then
            domgraph.delete_edge(edge)
        end

        # look for opposing edges, change edge pair, delete if necessary,
        # restart
        opposing = domgraph.edge(edge.to, edge.from)

        if opposing then
            self_weight = edge.weight
            opposing_weight = opposing.weight

            edge.weight = self_weight - opposing_weight
            opposing.weight = opposing_weight - self_weight

            if edge.weight <= 0 then
                domgraph.delete_edge(edge)
            elsif opposing.weight <= 0 then
                domgraph.delete_edge(opposing)
            end
        end
    end

    return domgraph
end

def print_out_edges(g, name)
    node = g.node(name)

    puts "#{name}"

    g.out_edges(node).each do |edge|
        puts " |-> #{edge.to.name} (#{edge.weight})"
    end

    nil
end

def print_in_edges(g, name)
    node = g.node(name)

    g.in_edges(node).each do |edge|
        puts " |- #{edge.from.name} (#{edge.weight})"
    end

    puts " v"
    puts "#{name}"

    nil
end
