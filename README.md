## Installation

```smalltalk
Metacello new
  githubUser: 'Marpioux' project: 'GitLab-Commit-Follower' commitish: 'master' path: 'src';
  baseline: 'myproject';
  load
```

## API 


## Example 

Little script example : 

```smalltalk
glphApi := GitlabApi new 
	privateToken: #'<YOUR TOKEN>';
   hostUrl: '<YOU_GITLAB_API>';
	output: 'json';
	yourself.
	
model := GLHModel new.

modelImporter := GitlabModelImporter new
	repoApi: glphApi;
	glhModel: model; 
	withFiles: false;
	withCommitsSince: 0 day;
	withCommitDiffs: true.
	
tracer := Tracer new 
   glhImporter: modelImporter;
   gitlabApi: glphApi;
   project: (modelImporter importProject: <YOUR_PROJECT_ID>);
   filter: "Enter a string to filter commits by message, or an integer corresponding to a GitLab user ID to filter by author."
   yourself.
			
tracer findRelevantChangesInFiles
			
```
