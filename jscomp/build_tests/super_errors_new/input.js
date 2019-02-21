
const fs = require('fs')
const path = require('path')
const child_process = require('child_process')

// if bsc doesn't exist, we're probably on CI
const bsc = fs.existsSync('lib/bsc') ? 'lib/bsc' : 'bsc'
const refmt = fs.existsSync('lib/bsrefmt') ? 'lib/bsrefmt' : 'bsrefmt'

const expectedDir = path.join(__dirname, 'expected')

const fixtures = fs
  .readdirSync(path.join(__dirname, 'fixtures'))
  .filter(fileName => path.extname(fileName) === '.re')

const runtime = path.join(__dirname, '..', '..', 'runtime')
const colors = true
const prefix = `${bsc} -bs-re-out -I ${runtime} -pp '${refmt} --print binary' -w +10-40+6+7+27+32..39+44+45`

const updateTests = process.argv[2] === 'update'

const thisShouldErrorButDidnt = 'lol'

function postProcessErrorOutput(output) {
  output = output.trimRight()
  output = output.replace(/\/[^ ]+?jscomp\/build_tests\/super_errors_new\//g, '/.../')
  output = output.replace(/[^ ]+?\/refmt.exe /gim, '/.../refmt.exe ')
  return output
}

fixtures.forEach(fileName => {
  const fullFilePath = path.join(__dirname, 'fixtures', fileName)
  const command = `${prefix} -color ${colors ? 'always' : 'never'} -bs-super-errors -impl ${fullFilePath}`
  let asd
  try {
    asd = child_process.execSync(command, {stdio: 'pipe'})
    // TODO: test this codepath
    throw new Error(thisShouldErrorButDidnt)
  } catch (e) {
    if (e.message === thisShouldErrorButDidnt) {

    } else {
      const actualErrorOutput = postProcessErrorOutput(e.stderr.toString())
      const expectedFilePath = path.join(expectedDir, fileName + '.expected')
      if (updateTests) {
        fs.writeFileSync(expectedFilePath, actualErrorOutput)
      } else {
        const expectedErrorOutput = postProcessErrorOutput(fs.readFileSync(expectedFilePath, {encoding: 'utf-8'}))
        if (expectedErrorOutput !== actualErrorOutput) {
          console.error(`The old and new error output for the test ${fullFilePath} aren't the same`)
          console.error('Old:')
          console.error(expectedErrorOutput)
          console.error('New:')
          console.error(actualErrorOutput)
        }
      }
    }
  }
})
