const { exec } = require('child_process');

exec('npm run build', (error, stdout, stderr) => {
  console.log(stdout);
  console.error(error);
  console.error(stderr);
});

while(1) {

}
