# HTM - Hierarchical Temporal Memory cortical learning algorithms Ruby implementation

[![Dependency Status](https://gemnasium.com/romain1189/htm.png)](https://gemnasium.com/romain1189/htm)
[![Build Status](https://secure.travis-ci.org/romain1189/htm.png?branch=master)](http://travis-ci.org/romain1189/htm)

[Numenta](http://www.numenta.com/)'s Hierarchical Temporal Memory (HTM) is a machine learning technology that aims to capture the structural and algorithmic properties of the neocortex.

This project is an unofficial attempt to implement those algorithms. The code is based on Numenta's [paper](http://www.numenta.com/htm-overview/education/HTM_CorticalLearningAlgorithms.pdf) version 0.2.1

## I'm too lazy to follow those links, just give me a brief description

HTM networks are modeled on the neocortex, the seat of human intelligence. They capture the essence of how humans learn, recognize patterns, and make predictions. At the heart of every HTM network is a set of learning algorithms which model the organization and behavior of a layer of neurons in the neocortex. In the same way that humans learn from their environment, the HTM cortical learning algorithms perform the difficult task of discovering the temporal structure in large and complex data streams. By observing how data changes over time an HTM network learns what patterns are significant and causally related. After learning, an HTM network can recognize novel patterns and make predictions.

## Installation

Add this line to your application's Gemfile:

    gem 'htm'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install htm

Inside of your Ruby program do:

    require 'htm'

...to pull it in as a dependency.

## Documentation

The following API documentation is available :

* [YARD API documentation](http://www.rubydoc.info/github/romain1189/htm/master/frames)

## Usage

See the examples folder

## Suggested Reading

* Jeff Hawkins, Sandra Blakeslee. *On intelligence*. Times Books, 2004. ISBN-10: 0805074562
* Jeff Hawkins, Subutai Ahmad, Donna Dubinsky. [Hierarchical Temporal Memory including HTM Cortical Learning Algorithms](http://www.numenta.com/htm-overview/education/HTM_CorticalLearningAlgorithms.pdf). Numenta, 2011. version 0.2.1

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
