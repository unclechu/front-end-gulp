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
	dir
	_args
	{
		cwd=dir
		
		fwd-output=no
		fwd-stdout=no
		fwd-stderr=yes
		
		resolve-output=no
		resolve-stdout=no
		resolve-stderr=yes
	}
) --> new Promise (resolve, reject)!->
	const bin  = path.join dir, \front-end-gulp
	const args = ["--cwd=#dir"] ++ _args
	const proc = spawn bin, args, {cwd}
	
	const stdio-aggregate = [[],[],[]]
	
	proc.stdio.1.on \data, !->
		stdio-aggregate.0.push it if resolve-output or (resolve-stdout and resolve-stderr)
		stdio-aggregate.1.push it if resolve-stdout
		process.stdout.write   it if fwd-stdout or fwd-output
	proc.stdio.2.on \data, !->
		stdio-aggregate.0.push it if resolve-output or (resolve-stdout and resolve-stderr)
		stdio-aggregate.2.push it if resolve-stderr
		process.stderr.write   it if fwd-stderr or fwd-output
	
	code <-! proc.on \close
	const stdio-done = stdio-aggregate.map -> Buffer.concat it
	switch code
	| 0 =>
		resolve switch
			| resolve-output or (resolve-stdout and resolve-stderr) =>
				stdio-aggregate.0.to-string!
			| resolve-stdout => stdio-aggregate.1.to-string!
			| resolve-stderr => stdio-aggregate.2.to-string!
	| _ => reject new Error "Exit code: #code"

const get-file-contents-p = (file)--> new Promise (resolve, reject)!->
	err, contents <-! fs.read-file file
	(reject err ; return) if err?
	resolve contents

const is-file-exists-p = (file)--> new Promise (resolve)!->
	fs.exists file, resolve

const check-for-exists-p = (file-list, exists)-->
	*<- Promise.coroutine >> (do)
	yield do
		Promise.all file-list.map (-> is-file-exists-p it)
			|> (.should.become [exists for til file-list.length])

const check-for-exists-and-get-contents-p = (file-list)-->
	*<- Promise.coroutine >> (do)
	yield check-for-exists-p file-list, yes
	yield Promise.all file-list.map (-> get-file-contents-p it)

const buf-zip-cmp = (should-be-list, build-list)-->
	*<-! Promise.coroutine >> (do)
	expect build-list.length .to.equal should-be-list.length
	build-list
		|> (.map (it, idx)-> it.equals should-be-list[idx])
		|> (.for-each !-> expect it .to.equal yes)

# coroutine wrap with exception catcher
const co-caught = (done)--> Promise.coroutine >> (do) >> (.catch done)

const get-build-path = (fpath, build-dir, file-get-f, it)-->
	it |> (-> path.join "#it/#build-dir", file-get-f it) |> (fpath)

const check-if-its-cleaned-p = (exts, fpath, build-dir, file-get-f)-->
	*<-! Promise.coroutine >> (do)
	const build-paths = exts.map get-build-path fpath, build-dir, file-get-f
	yield check-for-exists-p build-paths, no

const should-compare-p = (exts, fpath, build-dir, file-get-f)-->
	*<-! Promise.coroutine >> (do)
	
	const should-be = yield Promise.all exts.map ->
		get-file-contents-p fpath do
			path.join "#it/should-be", file-get-f it
	
	const build-paths = exts.map get-build-path fpath, build-dir, file-get-f
	const build       = yield check-for-exists-and-get-contents-p build-paths
	
	yield buf-zip-cmp should-be, build

describe \building-from-sources, (x)!->
	
	describe \#stylus-and-livescript, (x)!->
		const test-dir = path.join __dirname, \stylus-and-livescript
		const should-be-file = (dirname, test-task-name)-->
			path.join test-dir, dirname, test-task-name
		
		it "ask for help", (done)!->
			*<-! (co-caught done)
			
			yield do
				run-p test-dir, <[ help ]>, {+resolve-stdout}
					|> (.should.be.fulfilled)
					|> ->
						[
							"Starting 'help'"
							"Main Tasks"
							"Sub Tasks"
							"scripts-test-1"
							"styles-test-1"
							"clean:scripts-test-1"
							"clean:styles-test-1"
							"watch:scripts-test-1"
							"watch:styles-test-1"
							"Finished 'help'"
						] .reduce _, it <|
						(promise, string-match)->
							(promise.and.eventually.have.string string-match)
			
			do done
		
		it "fall on unknown task name", (done)!->
			*<-! (co-caught done)
			yield do
				run-p test-dir, <[ unknown-task-name ]>, {}
					|> (.should.be.rejected)
			do done
		
		it "simple build (test-1)", (done)!->
			*<-! (co-caught done)
			
			const fpath       = should-be-file \test-1
			const exts        = <[ css js ]>
			const tasks       = <[ styles-test-1 scripts-test-1 ]>
			const clean-tasks = tasks.map (-> "clean:#it")
			
			const args-preset = -> it exts, fpath, \build, (-> "build.#it")
			
			yield run-p test-dir, clean-tasks, {}
			yield args-preset check-if-its-cleaned-p
			yield run-p test-dir, tasks, {}
			yield args-preset should-compare-p
			
			do done
