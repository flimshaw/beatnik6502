const fs = require('fs')
const path = require('path')
const readline = require('readline')
const folderPath = '../dict'

const dict = {}

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
    // console.log(, line);
    dict[type].push(line)
  });
  // console.log(fs.readFileSync())
})

setTimeout(() => console.log(dict), 1000)
