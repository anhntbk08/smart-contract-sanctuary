ava: address
eden: HashMap[address, bool]
bible : HashMap[address, bytes32]

@external
def __init__():
  self.ava = msg.sender

@external
def adam(eve: address):
  assert msg.sender == self.ava
  self.ava = eve

@external
@payable
def play(verse: String[256]):
  send(self.ava, msg.value)
  self.bible[msg.sender] = sha256(verse)
  self.eden[msg.sender] = True

@external
@payable
def pray(prayer: address, poem: bytes32):
  assert msg.sender == self.ava
  assert self.bible[prayer] == poem
  assert self.eden[prayer]
  send(prayer, msg.value)
  self.eden[prayer] = False