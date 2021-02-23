# frozen_string_literal: true

module Decidim
  module Fictions
    class FictionInputFilter < Decidim::Core::BaseInputFilter
      include Decidim::Core::HasPublishableInputFilter

      graphql_name "FictionFilter"
      description "A type used for filtering fictions inside a participatory space.

A typical query would look like:

```
  {
    participatoryProcesses {
      components {
        ...on Fictions {
          fictions(filter:{ publishedBefore: \"2020-01-01\" }) {
            id
          }
        }
      }
    }
  }
```
"
    end
  end
end
