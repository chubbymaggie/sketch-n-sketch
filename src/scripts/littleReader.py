
def trimNewline(s): return s[:-1]
def write(f, s): f.write(s)
def writeLn(f, s): f.write(s + '\n')

def readLittle(name):
  f = '../examples/' + name + '.little'

  ## yield (name + ' = \"\n')
  ## following version is to facilitate line/col numbers:
  yield (name + ' =\n \"')

  for s in open(f):
    s = s.replace('\\','\\\\')
    s = s.replace('\"','\\\"')
    yield s

  yield ('\n\"\n\n')

