---
layout: post
title: "The kernel has a naming issue..."
date: 2022-09-19 17:57:18 -0300
categories: kernel-dev dco
---

# The kernel has a naming issue...

I'm trans. That means that my legal name is a dead name and doesn't match my identity. 
However, I still haven't changed my legal documents to the new name, and my new name doesn't look very consistent. 

What do I mean by that? Well, I've changed my preferred name many times. We have to assume that this kind of name can be changed but it will 
still represent the same person. 

I finally found a name that clicks, but it may be a matter of time to change that (hopefully it shouldn't happen). 

Problem is: contributing to the kernel requires some kind of legal binding: you have to sign the code that you send to the upstream. 
If something happens, and you happen to be on the court, you'll need to be identified by your legal name.

Anyways, I've spent some time researching on the discussion regarding names on the upstream community.

## What the DCO says
[1]

{% highlight text %}
then you just add a line saying:

Signed-off-by: Random J Developer <random@developer.example.org>

using your real name (sorry, no pseudonyms or anonymous contributions.) This will be done for you automatically if you use git commit -s. Reverts should also include “Signed-off-by”. git revert -s does that for you.
{% endhighlight %}

I saw a question on the kernelnewbies mailing list where the person asks what is considered a real name [2]. The answer brings an important point: your real name is a name that people know you from.

{% highlight text %}
So, if your legal name is "Alexis Shannon Dev" but everyone calls you "Al Dev"
or "Shan Dev", it's your "real name" and this fact can be established in court
beyond reasonable doubt. Same goes for legal deadnames -- as long as the
person is known to their personal friends by their preferred new name and this
fact can be established by witness testimony in court, it's a "real name"
(though, for sure, this would be a lot more complicated in court if it in no
way matches the person's legal papers).
{% endhighlight %}

## What are my options

1. Use my preferred name anyhow

    The problems are: it's not a legally binding name AFAIK (although it is possible to add it to my ID here in Brazil – but that name can be changed, even in such a legal document). Also, I'm still using the old preferred name with my employer. I will make this change soon, but as I said, preferred names may not be consistent.

    I also don't know the implications of changing this name in the future. Since old contributions will keep my legal name, it should be fine, although my identity will be all over the place. 

2. Use my legal name (dead name)
    This seems to be the current solution, which is so bad :(

3. Use a pseudonym

    This is not allowed by the DCO.  

4. Use an abbreviation

    DCO doesn't allow anonymous contributions, which means no abbreviations. Discussion on [3]. The author brings up this point:

    {% highlight text %}
    Another reason for signing with initials is to ensure that other people 
    cannot infer anything about the author's gender. Women especially might 
    choose to do this to avoid the harassment that a female name can attract, 
    as shown in these studies for example:

    https://ece.umd.edu/news/story/study-finds-femalename-chat-users-get-25-times-more-malicious-messages
    https://www.reach3insights.com/women-gaming-study
    If we forbid people from contributing in a gender-neutral way, many may 
    feel they cannot contribute at all. Again, I think that when we exclude 
    these people we are all worse off as a result.
    {% endhighlight%}

## Conclusion

Just read the article on [4].

## References

\[1][Developer’s Certificate of Origin 1.1](https://www.kernel.org/doc/html/latest/process/submitting-patches.html#developer-s-certificate-of-origin-1-1)
\[2][What is considered a real name?](https://www.mail-archive.com/kernelnewbies@kernelnewbies.org/msg22178.html)
\[3][[PATCH] ARM: dts: sun8i: h3: orangepi-plus: Fix Ethernet PHY mode](https://lore.kernel.org/lkml/CAGRGNgVSze9yW6KTsC=KGCVOJLzck65J-f9v8y30iBw7k0KXQA@mail.gmail.com/T/)
\[4][Falsehoods Programmers Believe About Names](https://www.kalzumeus.com/2010/06/17/falsehoods-programmers-believe-about-names/)
