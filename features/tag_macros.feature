Feature: Tags that modify scenarios
  
  @split_test
  Scenario: Standard users
    Then I should see "<result>"
  
  @outline
  Scenario Outline: Something
    Given I am in group "A"
  
  @outline
  Scenario Outline: Something
    Given I am in group "<group>"
  Examples:
    | group |
    | A     |
    | B     |

