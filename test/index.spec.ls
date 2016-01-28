require! {
	fs
	path
	\child_process : {spawn}
	
	bluebird: Promise
	chai: {expect}
	mocha
}

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
	
	const build-exists =
		yield Promise.all file-list.map (-> is-file-exists-p it)
	
	build-exists.for-each (!-> expect it .to.equal yes)
	
	yield Promise.all file-list.map (-> get-file-contents-p it)

const buf-zip-cmp = (should-be-list, build-list)-->
	*<-! Promise.coroutine >> (do)
	expect build-list.length .to.equal should-be-list.length
	build-list
		|> (.map (it, idx)-> it.equals should-be-list[idx])
		|> (.for-each !-> expect it .to.equal yes)

# coroutine wrap with exception catcher
const co-caught = (done)--> Promise.coroutine >> (do) >> (.catch done)

describe \building-from-sources, (x)!->
	
	describe \#stylus-and-livescript, (x)!->
		const test-dir = path.join __dirname, \stylus-and-livescript
		const test-bin = path.join test-dir,  \front-end-gulp
		const should-be-file = (dirname, filename)-->
			path.join test-dir, dirname, filename
		
		it "simple build (test-1)", (done)!->
			*<-! (co-caught done)
			
			const fpath = should-be-file \test-1
			const exts  = <[ css js ]>
			
			yield run-p do
				test-bin
				[ "--cwd=#test-dir" \styles-test-1 \scripts-test-1 ]
				{ +fwd-stderr, cwd: test-dir }
			
			const should-be = yield Promise.all exts.map ->
				get-file-contents-p fpath "#it/should-be/build.#it"
			
			const build-paths =
				exts
					|> (.map -> "#it/build/build.#it")
					|> (.map fpath)
			
			const build = yield check-for-exists-and-get-contents-p build-paths
			
			yield buf-zip-cmp should-be, build
			
			do done
