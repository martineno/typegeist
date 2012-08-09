class Node
    def initialize(graph)
        graph.nodes << self
    end

    def project_into(other_graph)
        projection = Node.new(other_graph)
        projection.name = self.name
        projection.weight = self.weight

        return projection
    end

    attr_accessor :name
    attr_accessor :weight
end

class Edge
    def initialize(graph)
        graph.edges << self
    end

    def project_into(other_graph, node_projection)
        projection = Edge.new(other_graph)
        projection.from = node_projection[self.from]
        projection.to = node_projection[self.to]
        projection.weight = self.weight

        return projection
    end

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
        self.nodes.delete(node)
    end

    def delete_edge(edge)
        self.edges.delete(edge)
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
        node.weight = 0
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
            node.weight += style.characters

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
    
    loop do
        early_exit = false

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

                # we removed an edge, so we need to restart the pruning process
                early_exit = true
                break
            end
        end

        if !early_exit then
            break
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

def select_subgraph_naive(args)
    graph = args[:graph] or raise
    n = args[:n] or 25
    sigma_0 = args[:sigma_0] or 50000

    subgraph = Digraph.new
    subgraph_nodes = {}

    # copy nodes into subgraph
    # only copy the most popular n fonts
    model_nodes = graph.nodes.sort {|a,b| b.weight <=> a.weight}

    model_nodes.take(n).each do |node|
        subgraph_node = node.project_into(subgraph)
        subgraph_nodes[node] = subgraph_node
    end

    # copy edges into subgraph
    # only copy edges with a weight greater than sigma_0
    graph.edges.each do |edge|
        if subgraph_nodes[edge.from] && 
                subgraph_nodes[edge.to] && edge.weight > sigma_0 then
            edge.project_into(subgraph, subgraph_nodes)
        end
    end

    return subgraph
end

def select_subgraph_shape(args)
    graph = args[:graph] or raise
    n = args[:n] || 25              # number of nodes to select
    m_node = args[:m] || 1          # number of edges to select per node

    subgraph = Digraph.new
    subgraph_nodes = {}
    subgraph_edges = {}

    # copy nodes into subgraph
    # only copy the most popular n fonts
    model_nodes = graph.nodes.sort {|a,b| b.weight <=> a.weight}

    model_nodes.take(n).each do |node|
        subgraph_node = node.project_into(subgraph)
        subgraph_nodes[node] = subgraph_node
    end

    # copy edges into subgraph
    # only copy the highest-weight m_node in-edges and out-edges per node
    #
    # note: separate block because we need to ensure all the nodes have
    # projected first
    model_nodes.take(n).each do |node|
        in_edges = graph.edges.select { |edge| edge.to == node && subgraph_nodes[edge.from] && !subgraph_edges[edge] }
        out_edges = graph.edges.select { |edge| edge.from == node && subgraph_nodes[edge.to] && !subgraph_edges[edge] }

        in_edges.sort! {|a,b| b.weight <=> a.weight}
        out_edges.sort! {|a,b| b.weight <=> a.weight}

        in_edges.take(m_node).each do |edge|
            subgraph_edges[edge] = edge.project_into(subgraph, subgraph_nodes)
        end

        out_edges.take(m_node).each do |edge|
            subgraph_edges[edge] = edge.project_into(subgraph, subgraph_nodes)
        end
    end

    return subgraph
end

def graphvize(g, mode, n, sigma_0)
    require 'graphviz'
    require 'htmlentities'

    gvg = GraphViz.new(:G, :type => :digraph, :path => "C:/Program Files (x86)/Graphviz 2.28/bin")

    gvg.graph[:bgcolor] = "#656565"

    gvg.node[:fontname] = "Segoe UI Bold"
    gvg.node[:fontsize] = 16
    gvg.node[:shape] = "plaintext"
    gvg.node[:penwidth] = 3
    gvg.node[:color] = gvg.edge[:color] = "#D0D0D0"
    gvg.node[:fontcolor] = "#D0D0D0"

    gv_nodes = {}

    encoder = HTMLEntities.new

    g = select_subgraph_shape(:graph => g, :n => n)

    # copy nodes into graphviz graph
    g.nodes.each do |node|
        # graphviz expects unicode names to be output as html entities; convert
        # now
        encodedName = encoder.encode(node.name, :decimal)
        gv_node = gvg.add_nodes(encodedName)
        gv_nodes[node] = gv_node
    end

    # copy edges into graphviz graph
    g.edges.each do |edge|
        gvg.add_edges(gv_nodes[edge.from], gv_nodes[edge.to])
    end

    return gvg
end

if __FILE__ == $0 then
    # being executed from the command line.
    # first argument is a scrape database, second is a filename to output a 
    # graph to, third is the number of nodes to put in the graph
    domgraph = reduced_dominator_graph(ARGV[0])
    graphviz_graph = graphvize(domgraph, 'naive', ARGV[2].to_i, ARGV[3].to_i)
    graphviz_graph.output(:svg => ARGV[1])
end