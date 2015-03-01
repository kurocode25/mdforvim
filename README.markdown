mdforvim
========

## Overview

"mdforvim" is vim plugin for dealing Markdown langage more easily, which is independent of ex-parser.It has follow functions;

1. converting instantly Markdown lang. to HTML in current buffer
2. saving as HTML file without change original Markdown file
3. showing realtime preview by WEB browser during edit Markdown file

## Demo
### Conversion Markdown in current buffer

### Showing Realtime Preview

## Usage
### Instant conversion in current buffer
Please input follow command to convert from Markdown to HTML in current buffer.

```
:MdConvert
```

### Saving as HTML file
Please input follow command to save as HTML file.

```
:MdSaveAs <file name.html>
```

### Showing Realtime Preview
Please input follow command to start preview.

```
:MdPreview
```

If you finish preview, we recommend run follow command before close WEB brwoser.

```
:StopMdPreview
```

## Install
If you use vundle, please add follow phrase your ~/.vimrc(or \_vimrc) and install by Vundle.
```
Bundle 'kurocode25/mdforvim'
```

If you use NeoBundle,please add follow phrase your ~/.vimrc(or \_vimrc) and install by NeoBundle.

```
NeoBundleFetch 'kurocode25/mdforvim'
```

## Licence
[MIT](http://opensource.org/licenses/mit-license.php) &copy; Kuro_CODE25

## Author
[Kuro_CODE25](https://github.com/kurocode25)  
