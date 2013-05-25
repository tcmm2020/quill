Scribe = require('./scribe')


class Scribe.Renderer
  @DEFAULTS:
    formats: 'default'
    keepHTML: false
    id: 'editor'

  @DEFAULT_STYLES:
    'div.editor': {
      'bottom': '10px'
      'font-family': "'Helvetica', 'Arial', san-serif"
      'font-size': '13px'
      'left': '15px'
      'line-height': '15px'
      'outline': 'none'
      'position': 'absolute'
      'right': '15px'
      'tab-size': '4'
      'top': '10px'
      'white-space': 'pre-wrap'
    }
    'html' : { 'height': '100%' }
    'body' : { 'cursor': 'text', 'height': '100%', 'margin': '0px', 'padding': '0px'}
    'div.line:last-child': { 'padding-bottom': '10px' }
    'a'    : { 'text-decoration': 'underline' }
    'b'    : { 'font-weight': 'bold' }
    'i'    : { 'font-style': 'italic' }
    's'    : { 'text-decoration': 'line-through' }
    'u'    : { 'text-decoration': 'underline' }
    'ol'   : { 'margin': '0px', 'padding': '0px' }
    'ul'   : { 'list-style-type': 'disc', 'margin': '0px', 'padding': '0px' }
    'ol.indent-1' : { 'list-style-type': 'decimal' }
    'ol.indent-2' : { 'list-style-type': 'lower-alpha' }
    'ol.indent-3' : { 'list-style-type': 'lower-roman' }
    'ol.indent-4' : { 'list-style-type': 'decimal' }
    'ol.indent-5' : { 'list-style-type': 'lower-alpha' }
    'ol.indent-6' : { 'list-style-type': 'lower-roman' }
    'ol.indent-7' : { 'list-style-type': 'decimal' }
    'ol.indent-8' : { 'list-style-type': 'lower-alpha' }
    'ol.indent-9' : { 'list-style-type': 'lower-roman' }
    '.indent-1' : { 'margin-left': '2em' }
    '.indent-2' : { 'margin-left': '4em' }
    '.indent-3' : { 'margin-left': '6em' }
    '.indent-4' : { 'margin-left': '8em' }
    '.indent-5' : { 'margin-left': '10em' }
    '.indent-6' : { 'margin-left': '12em' }
    '.indent-7' : { 'margin-left': '14em' }
    '.indent-8' : { 'margin-left': '16em' }
    '.indent-9' : { 'margin-left': '18em' }

  @DEFAULT_FORMATS = ['bold', 'italic', 'strike', 'underline', 'link', 'background', 'color', 'family', 'size']

  @objToCss: (obj) ->
    return _.map(obj, (value, key) ->
      innerStr = _.map(value, (innerValue, innerKey) -> return "#{innerKey}: #{innerValue};" ).join(' ')
      return "#{key} { #{innerStr} }"
    ).join("\n")


  constructor: (@container, options) ->
    @options = _.extend(Scribe.Renderer.DEFAULTS, options)
    this.createFrame()
    @formats = {}
    if @options.formats == 'default'
      _.each(Scribe.Renderer.DEFAULT_FORMATS, (formatName) =>
        className = formatName[0].toUpperCase() + formatName.slice(1)
        this.addFormat(formatName, new Scribe.Format[className](@root))
      )

  addContainer: (container, before = false) ->
    this.runWhenLoaded( =>
      refNode = if before then @root else null
      @root.parentNode.insertBefore(container, refNode)
    )

  addFormat: (name, format) ->
    @formats[name] = format

  addStyles: (styles) ->
    this.runWhenLoaded( =>
      style = @root.ownerDocument.createElement('style')
      style.type = 'text/css'
      css = Scribe.Renderer.objToCss(styles)
      if style.styleSheet?
        style.styleSheet.cssText = css
      else
        style.appendChild(@root.ownerDocument.createTextNode(css))
      # Firefox needs defer
      _.defer( =>
        @root.ownerDocument.head.appendChild(style)
      )
    )

  createFormatContainer: (name, value) ->
    if @formats[name]
      return @formats[name].createContainer(value)
    else
      return @root.ownerDocument.createElement('SPAN')

  createFrame: ->
    html = @container.innerHTML
    @container.innerHTML = ''
    @iframe = @container.ownerDocument.createElement('iframe')
    @iframe.frameborder = 0
    @iframe.height = @iframe.width = '100%'
    @container.appendChild(@iframe)
    window.test = @iframe
    doc = @iframe.contentWindow.document
    @root = doc.createElement('div')
    @root.classList.add('editor')
    @root.id = @options.id
    @root.innerHTML = Scribe.Normalizer.normalizeHtml(html) if @options.keepHTML
    styles = _.map(@options.styles, (value, key) ->
      obj = Scribe.Renderer.DEFAULT_STYLES[key] or {}
      return _.extend(obj, value)
    )
    styles = _.extend(Scribe.Renderer.DEFAULT_STYLES, styles)
    this.addStyles(styles)
    this.runWhenLoaded( =>
      @iframe.contentWindow.document.body.appendChild(@root) # Firefox does not like doc.body
    )

  getFormat: (container) ->
    for name,format of @formats
      value = format.matchContainer(container)
      return [name, value] if value
    return []

  runWhenLoaded: (fn) ->
    return fn.call(this) if @iframe.contentWindow.document.readyState == 'complete'
    if @iframe.contentWindow.onload
      @iframe.contentWindow.onload = _.wrap(@iframe.contentWindow.onload, (wrapper) =>
        wrapper.call(this)
        fn.call(this)
      )
    else
      @iframe.contentWindow.onload = fn


module.exports = Scribe
