#!/usr/local/bin/story_xml

<story
    name="Test Book for Writing Tools"
    author="Christopher Caldwell"
    copyright="2018 Christopher Caldwell"
    ISBN="UNKNOWN"
    colors="#c0e0a0,#a0d0a0">

    <include file="variables.xml"/>

    <promotion>
        This is the promotion for the book.
    </promotion>

    <dedication>
        This is the dedication for the book.
    </dedication>

    <creator_info>
        Presumably this book was created by somebody.
    </creator_info>

    <related
        name="These Things Happen"
	author="Chris Caldwell"
	src="https://www.amazon.com/dp/1649218532"
	/>

    <summary>
        This is the summary for entire story.
    </summary>

    <overview>
        This is an overview.
    </overview>

    <chapter name="Test Book for Writing Tools">
        <summary>
	    In which we discover why discover the joys of testing.
	</summary>
	<subchapter name="No Comment">
	    <summary>
	    </summary>
	    <text>
	        This is a test.
	    </text>
	</subchapter>
    </chapter>
</story>
