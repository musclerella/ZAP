//
//  FileExtensionMap.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/5/24.
//

import Foundation

// THIS FILE SHOULD REFLECT THE SAME MIME TYPE VALUES as the `MimeType` enum
struct FileExtensionMap {
    static let extensions: [FileExtension: MimeType] = [
        FileExtension.aac: MimeType.aac,
        FileExtension.abw: MimeType.abw,
        FileExtension.apng: MimeType.apng,
        FileExtension.arc: MimeType.arc,
        FileExtension.avif: MimeType.avif,
        FileExtension.avi: MimeType.avi,
        FileExtension.azw: MimeType.azw,
        FileExtension.bin: MimeType.bin,
        FileExtension.bmp: MimeType.bmp,
        FileExtension.bz: MimeType.bz,
        FileExtension.bz2: MimeType.bz2,
        FileExtension.cda: MimeType.cda,
        FileExtension.csh: MimeType.csh,
        FileExtension.css: MimeType.css,
        FileExtension.csv: MimeType.csv,
        FileExtension.doc: MimeType.doc,
        FileExtension.docx: MimeType.docx,
        FileExtension.eot: MimeType.eot,
        FileExtension.epub: MimeType.epub,
        FileExtension.gz: MimeType.gz,
        FileExtension.gif: MimeType.gif,
        FileExtension.htm: MimeType.htm,
        FileExtension.html: MimeType.html,
        FileExtension.ico: MimeType.ico,
        FileExtension.ics: MimeType.ics,
        FileExtension.jar: MimeType.jar,
        FileExtension.jpeg: MimeType.jpeg,
        FileExtension.jpg: MimeType.jpg,
        FileExtension.js: MimeType.js,
        FileExtension.mjs: MimeType.mjs,
        FileExtension.json: MimeType.json,
        FileExtension.jsonld: MimeType.jsonld,
        FileExtension.mid: MimeType.mid,
        FileExtension.midi: MimeType.midi,
        FileExtension.mp3: MimeType.mp3,
        FileExtension.mp4: MimeType.mp4,
        FileExtension.mpeg: MimeType.mpeg,
        FileExtension.mpkg: MimeType.mpkg,
        FileExtension.odp: MimeType.odp,
        FileExtension.ods: MimeType.ods,
        FileExtension.odt: MimeType.odt,
        FileExtension.oga: MimeType.oga,
        FileExtension.opus: MimeType.opus,
        FileExtension.ogv: MimeType.ogv,
        FileExtension.ogx: MimeType.ogx,
        FileExtension.otf: MimeType.otf,
        FileExtension.png: MimeType.png,
        FileExtension.pdf: MimeType.pdf,
        FileExtension.php: MimeType.php,
        FileExtension.ppt: MimeType.ppt,
        FileExtension.pptx: MimeType.pptx,
        FileExtension.rar: MimeType.rar,
        FileExtension.rtf: MimeType.rtf,
        FileExtension.sh: MimeType.sh,
        FileExtension.svg: MimeType.svg,
        FileExtension.tar: MimeType.tar,
        FileExtension.tif: MimeType.tif,
        FileExtension.tiff: MimeType.tiff,
        FileExtension.ts: MimeType.ts,
        FileExtension.ttf: MimeType.ttf,
        FileExtension.txt: MimeType.txt,
        FileExtension.vsd: MimeType.vsd,
        FileExtension.wav: MimeType.wav,
        FileExtension.weba: MimeType.weba,
        FileExtension.webm: MimeType.webm,
        FileExtension.webp: MimeType.webp,
        FileExtension.woff: MimeType.woff,
        FileExtension.woff2: MimeType.woff2,
        FileExtension.xhtml: MimeType.xhtml,
        FileExtension.xls: MimeType.xls,
        FileExtension.xlsx: MimeType.xlsx,
        FileExtension.xml: MimeType.xml,
        FileExtension.xul: MimeType.xul,
        FileExtension.zip: MimeType.zip,
        FileExtension._7z: MimeType._7z
    ]
}

enum FileExtension: String {
    case aac
    case abw
    case apng
    case arc
    case avif
    case avi
    case azw
    case bin
    case bmp
    case bz
    case bz2
    case cda
    case csh
    case css
    case csv
    case doc
    case docx
    case eot
    case epub
    case gz
    case gif
    case htm, html
    case ico
    case ics
    case jar
    case jpeg, jpg
    case js, mjs
    case json
    case jsonld
    case mid
    case midi
    case mp3
    case mp4
    case mpeg
    case mpkg
    case odp
    case ods
    case odt
    case oga, opus
    case ogv
    case ogx
    case otf
    case png
    case pdf
    case php
    case ppt
    case pptx
    case rar
    case rtf
    case sh
    case svg
    case tar
    case tif, tiff
    case ts
    case ttf
    case txt
    case vsd
    case wav
    case weba
    case webm
    case webp
    case woff
    case woff2
    case xhtml
    case xls
    case xlsx
    case xml
    case xul
    case zip
//    case _3gp = "video/3gpp" //TODO: If video is not present need to use audio version
//    case _3g2 = "video/3gpp2" //TODO: If video is not present need to use audio version
    case _7z

}
