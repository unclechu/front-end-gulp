require! {
	path
	\child_process : {spawn}
	
	bluebird: Promise
	chai
	mocha
}

do chai.should

# promised spawn
const run-p = (
	bin
	args
	{
		fwd-output=no
		fwd-stdout=no
		fwd-stderr=no
		cwd
	}
) -> new Promise (resolve, reject)!->
	const stdio = [
		null
		if fwd-stdout or fwd-output then process.stdout else null
		if fwd-stderr or fwd-output then process.stderr else null
	]
	const proc = spawn bin, args, {stdio, cwd}
	code <-! proc.on \close
	switch code
	| 0 => do resolve
	| _ => reject new Error "Exit code: #code"

# coroutine wrap with exception catcher
const co-caught = (done)-> Promise.coroutine >> (do) >> (.catch done)

describe \building-from-sources, (x)!->
	describe \#stylus-and-livescript, (x)!->
		it "simple build (test-1)", (done)!->
			const test-dir = path.join __dirname, \stylus-and-livescript
			const test-bin = path.join test-dir,  \front-end-gulp
			*<- (co-caught done)
			yield run-p test-bin, ["--cwd=#test-dir"], {+fwd-stderr, cwd:test-dir}
			# TODO check if build files is correct
			do done
