path = require 'path'
{fs} = require 'atom'
temp = require 'temp'

describe "Whitespace", ->
  [editor, buffer] = []

  beforeEach ->
    directory = temp.mkdirSync()
    atom.project.setPath(directory)
    filePath = path.join(directory, 'atom-whitespace.txt')
    fs.writeFileSync(filePath, '')
    fs.writeFileSync(path.join(directory, 'sample.txt'), 'Some text.\n')
    editor = atom.project.openSync(filePath)
    buffer = editor.getBuffer()

    atom.packages.activatePackage('whitespace')

  it "strips trailing whitespace before an editor saves a buffer", ->
    atom.config.set("whitespace.ensureSingleTrailingNewline", false)

    # works for buffers that are already open when extension is initialized
    editor.insertText("foo   \nbar\t   \n\nbaz")
    editor.save()
    expect(editor.getText()).toBe "foo\nbar\n\nbaz"

    # works for buffers that are opened after extension is initialized
    editor = atom.project.openSync('sample.txt')
    editor.moveCursorToEndOfLine()
    editor.insertText("           ")

    editor.save()
    expect(editor.getText()).toBe 'Some text.\n'

  describe "when the edit session is destroyed", ->
    beforeEach ->
      atom.config.set("whitespace.ensureSingleTrailingNewline", false)

      buffer.retain()
      editor.destroy()

    afterEach ->
      buffer.release()

    it "unsubscribes from the buffer", ->
      buffer.setText("foo   \nbar\t   \n\nbaz")
      buffer.save()
      expect(buffer.getText()).toBe "foo   \nbar\t   \n\nbaz"

  it "does not trim trailing whitespace if removeTrailingWhitespace is false", ->
    atom.config.set("whitespace.removeTrailingWhitespace", false)

    editor.insertText "don't trim me "
    editor.save()
    expect(editor.getText()).toBe "don't trim me \n"

  describe "whitespace.ensureSingleTrailingNewline config", ->
    [originalConfigValue] = []
    beforeEach ->
      originalConfigValue = atom.config.get("whitespace.ensureSingleTrailingNewline")
      expect(originalConfigValue).toBe true

    afterEach ->
      atom.config.set("whitespace.ensureSingleTrailingNewline", originalConfigValue)

    it "adds a trailing newline when there is no trailing newline", ->
      editor.insertText "foo"
      editor.save()
      expect(editor.getText()).toBe "foo\n"

    it "removes extra trailing newlines and only keeps one", ->
      editor.insertText "foo\n\n\n\n"
      editor.save()
      expect(editor.getText()).toBe "foo\n"

    it "leaves a buffer with a single trailing newline untouched", ->
      editor.insertText "foo\nbar\n"
      editor.save()
      expect(editor.getText()).toBe "foo\nbar\n"

    it "leaves an empty buffer untouched", ->
      editor.insertText ""
      editor.save()
      expect(editor.getText()).toBe ""

    it "leaves a buffer that is a single newline untouched", ->
      editor.insertText "\n"
      editor.save()
      expect(editor.getText()).toBe "\n"

    it "does not add trailing newline if ensureSingleTrailingNewline is false", ->
      atom.config.set("whitespace.ensureSingleTrailingNewline", false)

      editor.insertText "no trailing newline"
      editor.save()
      expect(editor.getText()).toBe "no trailing newline"

    it "does not move the cursor when the new line is added", ->
      editor.insertText "foo"
      expect(editor.getCursorBufferPosition()).toEqual([0,3])
      editor.save()
      expect(editor.getText()).toBe "foo\n"
      expect(editor.getCursorBufferPosition()).toEqual([0,3])

  describe "GFM whitespace trimming", ->
    grammar = null

    beforeEach ->
      spyOn(atom.syntax, "addGrammar").andCallThrough()
      atom.packages.activatePackage("language-gfm", sync: true)
      expect(atom.syntax.addGrammar).toHaveBeenCalled()
      grammar = atom.syntax.addGrammar.argsForCall[0][0]

    it "trims GFM text with a single space", ->
      editor.setGrammar(grammar)
      editor.insertText "foo \nline break!"
      editor.save()
      expect(editor.getText()).toBe "foo\nline break!\n"

    it "leaves GFM text with double spaces alone", ->
      editor.setGrammar(grammar)
      editor.insertText "foo  \nline break!"
      editor.save()
      expect(editor.getText()).toBe "foo  \nline break!\n"

    it "trims GFM text with a more than two spaces", ->
      editor.setGrammar(grammar)
      editor.insertText "foo   \nline break!"
      editor.save()
      expect(editor.getText()).toBe "foo\nline break!\n"
