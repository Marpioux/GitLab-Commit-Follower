Class {
	#name : 'Tracer',
	#superclass : 'Object',
	#instVars : [
		'project',
		'glhImporter',
		'gitlabApi'
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

{ #category : 'creation' }
Tracer >> findImpactLinesInCurrentFiles [
	| commits file addedLines deletedLines jSon aCommitFollowed |
	
	commits := self retrieveCommitsByACR.
	jSon := OrderedCollection new.
	
	commits do: [ :commit | 
		  (commit diffs) do: [ :diff |
			 file := gitlabApi repositories getRawFile: diff name ofProject: project id.
			 addedLines :=  self cleanAddedLines: diff diffString.
			 deletedLines := self cleanDeletedLines: diff diffString.
			((self verifyAddLines: addedLines inFile: file) and:
			(self verifyDeletedLines: deletedLines inFile: file))
			 ifTrue:[
				aCommitFollowed := Dictionary new.
				aCommitFollowed at: 'file' put: (diff name).
				aCommitFollowed at: 'addLines' put: (addedLines asString).
				aCommitFollowed at: 'deletedLines' put: (deletedLines asString).
				aCommitFollowed at: 'author' put: (diff commit author_name).
				aCommitFollowed at: 'commit_id' put: (diff commit id).
				aCommitFollowed at: 'creation_date' put: ((diff commit created_at) asString).
				jSon add: aCommitFollowed.].
			 ].
		].
	^NeoJSONWriter toString: jSon.
	
]

{ #category : 'treatment' }
Tracer >> findNotesByAcr [
	| mrs notes notesACR |
	
	mrs := glhImporter importMergeRequests: project.
	notes := mrs flatCollect: [ :mr | glhImporter importNotesfromMergeRequest: mr].
	
	notesACR := notes select: [ :note | note author id == 2661 "=> par auteur principal"]. 
	
	^notesACR
	



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
	
	commitsACR := commits select: [ :commit | commit message asString includesSubstring: 'acr'  ].
	
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
