const fs = require('fs')
const path = require('path')
const readline = require('readline')
const folderPath = path.resolve(`${__dirname}`,'../dict')

const START_ADDR = 0x1300
const dict = {}
let offset = START_ADDR;

fs.readdirSync(folderPath).map(fileName => {
  const f = path.join(folderPath, fileName)
  const readInterface = readline.createInterface({
      input: fs.createReadStream(f),
      output: false,
      console: false
  });

  readInterface.on('line', function(line) {
    const type = fileName.split('.src')[0]
    if(dict[type] === undefined) dict[type] = []
    dict[type].push(line)
  });
})

// datablock = "jkldjfaskljfaklsjdfa"
//indexes = [16 bit indexes]



// dump a data block to represent the
// dictionary, with an index
function processDict(d) {
  const dictKeys = Object.keys(d)
  let i = 0;

  const datablocks = dictKeys.map(k => {
    let i = 0;
    let j = 0;
    let indices = dict[k].map(w => {
      j = i
      i += w.length
      return j
    })
    let lengths = dict[k].map(w => w.length)
    // each dict should be an array of indices
    // and a huge datablock
    return {
      name: k,
      data: dict[k].join(''),
      indices: indices,
      lengths: lengths,
    }
  })

  return datablocks
}

function getSize(block) {
  // console.log(block.data.length)
  return parseInt(block.data.length)+parseInt(block.indices.length*2)+parseInt(block.lengths.length)+1
}

function formatDatablock(datablocks) {
  let k = datablocks.map(d => {
    return d.indices;
  })
  let g = k.map((d,i) => {
    const s = `

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; ${datablocks[i].name}
      ;; total size: ${getSize(datablocks[i])} bytes
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;
      data_${datablocks[i].name}_data:
        ;; raw datablock
        .text "${datablocks[i].data}"
      data_${datablocks[i].name}_lengths:
        ;; word lengths
        .byte ${datablocks[i].lengths.map(v => `\$${v.toString(16)}`).join(',')}
      data_${datablocks[i].name}_indices:
        ;; indices
        .word ${d.map(v => `\$${(v+offset).toString(16)}`).join(',')}
      data_${datablocks[i].name}_count:
        .byte $${datablocks[i].indices.length.toString(16)}
    `;
    offset += getSize(datablocks[i])
    return s
  })
  let s = g.join('')
  s = `
  *=$1300
  ${s}
  `
  return s
}

setTimeout(() => console.log(formatDatablock(processDict(dict))), 500)
