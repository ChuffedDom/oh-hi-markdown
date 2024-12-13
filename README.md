## Purpose

A way to share lengthy notes in a formatted way without having to go through office applications to do so.

## Vision

To take a folder of Markdown files, no matter how big, or small, and build a website from it.

## Goals

- I want to have a Mac application to build the website by end of Friday
- I want to share a folder of example Markdown files with the product in order to test and see an example for yourself
- I want to have a no fuss means of getting a site without knowing/writing HTML and CSS

## Problem

As a person who takes all their notes in Markdown, there are times where I have to share that info with someone else as a collaborative project or publicly for a build in open project. But, sending over a folder of markdown files is:
- cumbersome e.g. send a zip file to someone on mobile to read a page is not very attractive as an offering
- ugly as many devices do not have a native way of rendering Markdown
Therefore, I have to copy everything to Google Drive or Notion, aka a non-preferred way of working, so I can send something to someone else.

If it is a small document, it is a large effort to send a small amount of info.

If it is a large document, then I have to copy everything over and go through and format all the headings because whilst other platform support Markdown, they don't auto format when you paste Markdown in to them. 

## Hypothesis

If I build a desktop app that will take a folder of Markdown files, and generate a folder of HTML files ready to be served, then people will be able to go from taking general notes and ideas that are jotted down to a blog or online book as quickly as possible without having to commit to paying for Obsidian, Notion, or other Productivity for Pay services.

## User Stories

As a Markdown freak...
	I need to keep my note taking and productivity organisation in one workflow and one tool without having to switch to share.
	I need to have a one click process to generate my site without having to edit HTML or CSS.
		which means I need to have a home page generated from the files in the folder.
		and not needing to install Git, Go, and all the other things for Hugo.

## Wireframes and Designs

![](https://raw.githubusercontent.com/ChuffedDom/oh-hi-markdown/main/New%20Wireframe%201%20(5).png)

![](https://raw.githubusercontent.com/ChuffedDom/oh-hi-markdown/main/App.png)
## Acceptance Criteria

- As a person who has downloaded the app, when I open it 
	- I have no folder selected
		- I see a folder select widget and a disabled "Generate site" button. 
	- When I have selected a folder of Markdown files, I can click "Generate site".

When a site is generating:
- then a folder is created in Documents named the same as the Markdown folder with `-site` appended
- then inside that folder the following is created
	- a folder named `pages` 
	- an `index.html`
- for each Markdown file:
	- a HTML document is created with the filename the same as the original file
		- e.g. `working hard.md` ➡️ `working-hard.html` (check for URL compliant)
		- then that is put inside a template HTML with
			- Link to simple.css CDN
			- Title that is the filename of the Markdown file
			- A home button
			- A H1 of that is the filename of the Markdown file
			- The date which is the last modified date from the file system
			- then the contents of the Markdown file gets refactored into HTML
	- in the `index.html` file
		- Title and H1 of the Folder name
		- The post widget
			- File name of the markdown file
			- Date as last modified date for the Markdown file
			- First 20 characters from the file with a truncated ellipsis
			- Read more text button with that is a hyperlink to that page

![](https://raw.githubusercontent.com/ChuffedDom/oh-hi-markdown/main/Pasted%20image%2020241212141822.png)

- As the site is generating I see a progress bar and the "Generate site" button is disabled again.
	- When generating is complete then I am prompted to view in Finder with an "open" button.

## Work to be Done

- [ ] Build a Landing Page
	- [ ] Google Hosting
	- [ ] Try web.app domain
	- [ ] icon
	- [ ] open graph
- [x] Design app
- [ ] Set up GitHub repo
- [ ] Create HTML Template
- [ ] Get a file's last modified date
- [x] Test Markdown folder
- [ ] Figure how to build for MacOS
- [ ] Local data persistence

Page Class
- filename
- htmlFilename
- 

## Resources

- https://pub.dev/packages/markdown
- https://simplecss.org/
- https://pub.dev/packages/filesystem_picker
- https://pub.dev/packages/path_provider

## Moving Forward

- Download Markdown from a page
- Chronological or Chapters? Journal, Book, Notes (recursive)
- Ship straight to netlify
- Ship straight to Firebase hosting
- Build for Windows
- Bring your own CSS
- View site as a preview
- Instructions how to deploy
- Live Server
- email Newsletter function
- RSS
- If site already exists? Update flow
- Image support
