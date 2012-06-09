class Node
    def initialize(graph)
        @graph = graph
        graph.nodes << self
    end

    attr_reader :graph
end

class Edge
    def initialize(graph)
        @graph = graph
        graph.edges << self
    end

    attr_reader :graph
    attr_accessor :from, :to
end

class Digraph
    def initialize
        self.nodes = []
        self.edges = []
    end

    attr_accessor :nodes, :edges
end

dg = Digraph.new
n = Node.new(dg)
e = Edge.new(dg)