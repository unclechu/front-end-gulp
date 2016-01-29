require! {
	fs
	path
	\child_process : {spawn}
	
	bluebird: Promise
	mocha
	chai
	chai: {expect}
	\chai-as-promised
}

do chai.should
chai.use chai-as-promised

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
) --> new Promise (resolve, reject)!->
	const stdio =
		null
		if fwd-stdout or fwd-output then process.stdout else null
		if fwd-stderr or fwd-output then process.stderr else null
	const proc = spawn bin, args, {stdio, cwd}
	code <-! proc.on \close
	switch code
	| 0 => do resolve
	| _ => reject new Error "Exit code: #code"

const get-file-contents-p = (file)--> new Promise (resolve, reject)!->
	err, contents <-! fs.read-file file
	(reject err ; return) if err?
	resolve contents

const is-file-exists-p = (file)--> new Promise (resolve)!->
	fs.exists file, resolve

const check-for-exists-and-get-contents-p = (file-list)-->
	*<- Promise.coroutine >> (do)
	
	yield do
		Promise.all file-list.map (-> is-file-exists-p it)
			|> (.should.become [yes for til file-list.length])
	
	yield Promise.all file-list.map (-> get-file-contents-p it)

const buf-zip-cmp = (should-be-list, build-list)-->
	*<-! Promise.coroutine >> (do)
	expect build-list.length .to.equal should-be-list.length
	build-list
		|> (.map (it, idx)-> it.equals should-be-list[idx])
		|> (.for-each !-> expect it .to.equal yes)

# coroutine wrap with exception catcher
const co-caught = (done)--> Promise.coroutine >> (do) >> (.catch done)

const should-compare = (exts, fpath, build-dir, file-get-f)-->
	*<-! Promise.coroutine >> (do)
	
	const should-be = yield Promise.all exts.map ->
		get-file-contents-p fpath do
			path.join "#it/should-be", file-get-f it
	
	const build-paths =
		exts
			|> (.map -> path.join "#it/#build-dir", file-get-f it)
			|> (.map fpath)
	
	const build = yield check-for-exists-and-get-contents-p build-paths
	
	yield buf-zip-cmp should-be, build

describe \building-from-sources, (x)!->
	
	describe \#stylus-and-livescript, (x)!->
		const test-dir = path.join __dirname, \stylus-and-livescript
		const test-bin = path.join test-dir,  \front-end-gulp
		const should-be-file = (dirname, test-task-name)-->
			path.join test-dir, dirname, test-task-name
		
		it "simple build (test-1)", (done)!->
			*<-! (co-caught done)
			
			const fpath = should-be-file \test-1
			const exts  = <[ css js ]>
			
			yield run-p do
				test-bin
				[ "--cwd=#test-dir" \styles-test-1 \scripts-test-1 ]
				{ +fwd-stderr, cwd: test-dir }
			
			yield should-compare exts, fpath, \build, (-> "build.#it")
			
			do done
