from dataclasses import dataclass, field

@dataclass
class Block:
    hash: str
    value: list = field(default_factory=list)
    children: dict = field(default_factory=dict)

    def getChild(self, hashPart):
        return self.children[hashPart]

    def insertChild(self, hashPart):
        if hashPart not in self.children:
            self.children[hashPart] = Block(
                hash=hashPart,
                value=[]
            )

        return self.children[hashPart]

    def nodes(self, key=[]):
        yield (key, self)

        for hashPart, child in self.children.items():
            yield from child.nodes(key + [hashPart])

    def items(self):
        for key, node in self.nodes():
            if len(node.value) != 0:
                yield (key, node)

    def forks(self):
        for key, node in self.nodes():
            if len(node.children) > 1:
                yield (key, node)

@dataclass
class BestTipTrie:
    # Empty root node, for empty keys
    root: Block = Block(hash=None, value=[])

    def get(self, chain):
        node = self.root
        for hashPart in chain:
            node = node.getChild(hashPart)
        return node.value

    # ([str], value)
    def insert(self, chain, value):
        node = self.root
        for hashPart in chain:
            node = node.insertChild(hashPart)
        node.value.append(value)

    def prefix(self):
        key = []
        node = self.root
        while len(node.children) == 1:
            keyPart = list(node.children.keys())[0]
            key.append(keyPart)
            node = node.children[keyPart]

        return key

    # ([str], [value])
    def items(self):
        yield from self.root.items()

    # ([str])
    def forks(self):
        yield from self.root.forks()
