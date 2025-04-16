Class {
	#name : 'Metrics',
	#superclass : 'Object',
	#instVars : [
		'tracer'
	],
	#category : 'GitlabFollower',
	#package : 'GitlabFollower'
}

{ #category : 'utilities' }
Metrics >> countCommit: aDictionnary [
	| aCommitArray boolean commitIdExist |

	aCommitArray := OrderedCollection new.
	commitIdExist := false.

	aDictionnary do: [:aDiff |
		aCommitArray do: [:aCommitId |
			boolean := aCommitId = (aDiff at: 'commit_id').
			boolean ifTrue: [ commitIdExist := true ].
		].
		commitIdExist ifFalse: [ aCommitArray add: (aDiff at: 'commit_id') ].
		commitIdExist := false.
	].

	^ aCommitArray size

]

{ #category : 'metrics' }
Metrics >> numberPerservedOrVanishedCommit [
	| perserved vanished json |
	
	json := tracer findRelevantChangesInFiles.
	json := NeoJSONReader fromString: json.
	perserved := json at: 'perserved'.
	vanished := json at: 'vanished'.
	
	perserved := self countCommit: perserved.
	vanished := self countCommit: vanished.
	
	json := Dictionary new.
	json at: 'perservedCommits' put: perserved.
	json at: 'vanishedCommits' put: vanished.
	json at: 'filter' put: tracer filter.
	json at: 'project_id' put: tracer project id.
	
	^ NeoJSONWriter toString: json.
	"^ 'For your filter : ', tracer filter asString, ' we have ', perserved asString, ' perserved commits and ', vanished asString, ' vanished commits'. "
]

{ #category : 'accessing' }
Metrics >> tracer [
	^tracer.
]

{ #category : 'accessing' }
Metrics >> tracer: anObject [
	tracer := anObject.
]
