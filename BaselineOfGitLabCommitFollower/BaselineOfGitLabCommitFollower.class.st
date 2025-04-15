Class {
	#name : 'BaselineOfGitLabCommitFollower',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfGitLabCommitFollower',
	#package : 'BaselineOfGitLabCommitFollower'
}

{ #category : 'baselines' }
BaselineOfGitLabCommitFollower >> baseline: spec [
"donne l'ensmebe des package requis pour la baseline (à inclure dans l'archive définis par Iceberg)"
   <baseline>
   spec for: #common do: [ 
   	self defineDependencies: spec.
   	self definePackages: spec.
   	self defineGroups: spec ]
   
]

{ #category : 'baselines' }
BaselineOfGitLabCommitFollower >> defineDependencies: spec [
"donne les ref vers le projet qui se trouve sur un depot distance (je crois)"
   spec baseline: 'GitlabAPI' with: [spec repository: 'github://Evref-BL/Gitlab-Pharo-API:main' ].
	spec baseline: 'GitLabHealth' with: [ spec repository: 'github://moosetechnology/GitProjectHealth:main/src' ].
]

{ #category : 'baselines' }
BaselineOfGitLabCommitFollower >> defineGroups: spec [
  "optional if you want to create specifc configuration of your baseline"
]

{ #category : 'baselines' }
BaselineOfGitLabCommitFollower >> definePackages: spec [

   spec
   	package: 'GitLabFollower' with: [ spec requires: #( 'GitlabAPI' 'GitLabHealth' ) ].
]
