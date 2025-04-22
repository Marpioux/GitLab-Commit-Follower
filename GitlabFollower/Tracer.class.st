Class {
	#name : 'Tracer',
	#superclass : 'Object',
	#instVars : [
		'project',
		'glhImporter',
		'gitlabApi',
		'filter'
	],
	#category : 'GitlabFollower',
	#package : 'GitlabFollower'
}

{ #category : 'treatment' }
Tracer >> cleanAddedLines: aString [
	|linesOfCode changeLine cleanedLines "byteString"|

	linesOfCode := aString lines.
	changeLine :=  linesOfCode select: [:line | 
    	(line beginsWith: '+') and: [(line beginsWith: '++') not]
	].

	cleanedLines := changeLine collect: [:line |
    	(line allButFirst) 
	].

"	byteString := (String streamContents: [:stream |
    	cleanedLines do: [:line | 
        	stream nextPutAll: line; cr
    	]]) asByteString."

	^cleanedLines.
]

{ #category : 'treatment' }
Tracer >> cleanDeletedLines: aString [
	|linesOfCode changeLine cleanedLines "byteString"|

	linesOfCode := aString lines.
	changeLine :=  linesOfCode select: [:line | 
    	(line beginsWith: '-') and: [(line beginsWith: '--') not]
	].

	cleanedLines := changeLine collect: [:line |
    	(line allButFirst) withBlanksCondensed 
	].

	"byteString := (String streamContents: [:stream |
    	cleanedLines do: [:line | 
        	stream nextPutAll: line; cr
    	]]) asByteString."

	^cleanedLines "byteString".
]

{ #category : 'accessing' }
Tracer >> filter [
	^filter
]

{ #category : 'accessing' }
Tracer >> filter: anObject [
	filter := anObject.
]

{ #category : 'creation' }
Tracer >> findImpactLinesInCurrentFiles [

	| commits file addedLines deletedLines jSonKeepedChanges jSonDeasepearedChanges aCommitFollowed |
	self
		deprecated: 'Use findRelevantChangesInFiles instead of current one'
		on: '15 April 2025'
		in:
		'Pharo-12.0.0+SNAPSHOT.build.1570.sha.3dafb8a476dfe88afa5aa6bf7b148beb9c11003f (64 Bit)'.

	commits := self retrieveCommitsByACR.
	jSonKeepedChanges := OrderedCollection new.
	jSonDeasepearedChanges := OrderedCollection new.

	commits do: [ :commit |
		commit diffs do: [ :diff |
			file := gitlabApi repositories
				        getRawFile: diff name
				        ofProject: project id.
			addedLines := self cleanAddedLines: diff diffString.
			deletedLines := self cleanDeletedLines: diff diffString.
			((self verifyAddLines: addedLines inFile: file) and:
				 (self verifyDeletedLines: deletedLines inFile: file)) ifTrue: [
				aCommitFollowed := Dictionary new.
				aCommitFollowed at: 'file' put: diff name.
				aCommitFollowed at: 'addLines' put: addedLines asString.
				aCommitFollowed at: 'deletedLines' put: deletedLines asString.
				aCommitFollowed at: 'author' put: diff commit author_name.
				aCommitFollowed at: 'commit_id' put: diff commit id.
				aCommitFollowed
					at: 'creation_date'
					put: diff commit created_at asString.
				jSonKeepedChanges add: aCommitFollowed ] ] ].
	^ NeoJSONWriter toString: jSonKeepedChanges
]

{ #category : 'treatment' }
Tracer >> findNotesByAcr [
	| mrs notes notesACR |
	
	mrs := glhImporter importMergeRequests: project.
	notes := mrs flatCollect: [ :mr | glhImporter importNotesfromMergeRequest: mr].
	
	notesACR := notes select: [ :note | note author id == 2661 "=> par auteur principal"]. 
	
	^notesACR
	



]

{ #category : 'creation' }
Tracer >> findRelevantChangesInFiles [
	| commitList currentFile addedLines removedLines preservedChanges vanishedChanges changeRecord json |

	commitList := self retrieveCommitsByACR.
	preservedChanges := OrderedCollection new.
	vanishedChanges := OrderedCollection new.

	commitList do: [:commit |
		glhImporter importDiffOfCommit: commit.
		(commit diffs) do: [:diff |
			currentFile := gitlabApi repositories getRawFile: diff name ofProject: project id.
			addedLines := self cleanAddedLines: diff diffString.
			removedLines := self cleanDeletedLines: diff diffString.

			changeRecord := Dictionary new.
			changeRecord at: 'file' put: diff name.
			changeRecord at: 'addLines' put: addedLines.
			changeRecord at: 'deletedLines' put: removedLines.
			changeRecord at: 'author' put: diff commit author_name.
			changeRecord at: 'commit_id' put: diff commit id.
			changeRecord at: 'creation_date' put: (diff commit created_at) asString.

			((self verifyAddLines: addedLines inFile: currentFile) and:
			 (self verifyDeletedLines: removedLines inFile: currentFile)) ifTrue: [
				preservedChanges add: changeRecord.
			] ifFalse: [
				changeRecord at: 'vanished_time' put: (self whenItVanished: diff).
				vanishedChanges add: changeRecord.
			].
		].
	].

	json := Dictionary new.
	json at: 'perserved' put: preservedChanges.
	json at: 'vanished' put: vanishedChanges.

	^NeoJSONWriter toString: json.

]

{ #category : 'accessing' }
Tracer >> gitlabApi [
	^gitlabApi
]

{ #category : 'accessing' }
Tracer >> gitlabApi: anObject [
	gitlabApi := anObject.
]

{ #category : 'accessing' }
Tracer >> glhImporter [ 
	^glhImporter
]

{ #category : 'accessing' }
Tracer >> glhImporter: anObject [
	glhImporter := anObject.
]

{ #category : 'accessing' }
Tracer >> project [
	^project
]

{ #category : 'accessing' }
Tracer >> project: anObject [
	project := anObject.
]

{ #category : 'treatment' }
Tracer >> retrieveCommitsByACR [
	| mrs commits commitsACR |
	
	mrs := glhImporter importMergeRequests: project.
	commits := mrs flatCollect: [ :mr | glhImporter importMergeRequestCommits: mr].
	
	commitsACR := commits select: [ :commit | 
		glhImporter importCreatorOfCommit: commit. 
		(filter isString) ifTrue: [  
		commit message asString includesSubstring: filter
		] ifFalse: [ 
		 commit commitCreator id = filter
		] ].
	
	^commitsACR 
	

]

{ #category : 'as yet unclassified' }
Tracer >> retrieveImpactLines: commit [

	| lines file |
	self
		deprecated:
		'Use findImpactLinesInCurrentFils instead of current one'
		on: '15 April 2025'
		in:
		'Pharo-12.0.0+SNAPSHOT.build.1570.sha.3dafb8a476dfe88afa5aa6bf7b148beb9c11003f (64 Bit)'.
	file := glhImporter repositories
		        getRawFile: commit diffs name
		        ofProject: project id
]

{ #category : 'treatment' }
Tracer >> verifyAddLines: addedLines inFile: file [
	| boolean |

	boolean := true.
	addedLines do: [ :line | 
		boolean ifTrue: [ 
			boolean := (file asString findString: line asString) > 0 ] 
		ifFalse: [ ^boolean ]].
	
	^boolean 
]

{ #category : 'treatment' }
Tracer >> verifyDeletedLines: deletedLines inFile: file [
	| boolean |
	
	boolean := true.
	deletedLines isNotEmpty ifTrue: [ 
		deletedLines do: [ :line |
			boolean ifTrue: [ 
							boolean := (file asString findString: line asString) = 0 ] 
					  ifFalse: [ ^boolean ].].
			 ] ifFalse: [ ^boolean ].
		
	^boolean.
]

{ #category : 'creation' }
Tracer >> whenItVanished: aDiff [ 
	| addedLinesSet remainingLinesSet commits vanished lastDate modifier modifiedOrVanishedLines |

	addedLinesSet := (self cleanAddedLines: aDiff diffString) reject: [:line | line isEmpty].
	remainingLinesSet := addedLinesSet copy.

	commits := glhImporter
		importCommitsOfProject: project
		since: aDiff commit created_at
		until: Date tomorrow.

	vanished := false.
	modifier := false.
	lastDate := nil.
	modifiedOrVanishedLines := OrderedCollection new.

	commits do: [ :commit |
		glhImporter importDiffOfCommit: commit.

		commit diffs do: [ :diff |
			| deletedLinesSet |
			deletedLinesSet := (self cleanDeletedLines: diff diffString) reject: [:line | line isEmpty].

			deletedLinesSet do: [:deleted |
				(addedLinesSet anySatisfy: [:added |
					added = deleted or: [
						(added copyWithoutAll: ' ' asSet) = (deleted copyWithoutAll: ' ' asSet)
					]
				]) ifTrue: [
					modifiedOrVanishedLines add: deleted.
					modifier := true.
					lastDate := commit created_at.
				].
			].

			remainingLinesSet := remainingLinesSet reject: [ :added |
				deletedLinesSet anySatisfy: [ :deleted |
					added = deleted or: [
						(added copyWithoutAll: ' ' asSet) = (deleted copyWithoutAll: ' ' asSet)
					]
				]
			].
		].

		(remainingLinesSet isEmpty) ifTrue: [
			vanished := true.
			^ {
				#lastDate -> lastDate asString.
				#vanished -> vanished.
				#modifier -> modifier.
				#vanishedLines -> modifiedOrVanishedLines asArray
			} asDictionary.
		].
	].

	^ {
		#lastDate -> lastDate asString.
		#vanished -> vanished.
		#modifier -> modifier.
		#vanishedLines -> modifiedOrVanishedLines asArray
	} asDictionary

]
