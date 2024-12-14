#Customer Lifetime Value Project

Project Overview

This project analyzes customer data from a fictional telecom company to understand patterns related to customer behavior, such as churn and plan usage, and calculate customer lifetime value. The analysis involves cleaning the data, exploring key metrics, and deriving insights to support business decisions.

##Key Objectives

Data Cleaning:

Remove duplicates.

Identify and handle missing values.

Ensure data consistency.

##Exploratory Data Analysis (EDA):

Calculate the total number of active users.

Examine user distribution by plan type and level.

Identify patterns and correlations in churn, monthly bill amounts, tenure, and other factors.

##Insights and Visualization:

Highlight trends in customer behavior.

Predict factors influencing customer churn.

Assist in decision-making to improve customer retention.

##Data Description

The dataset contains the following key columns:

Customer_ID: Unique identifier for each customer.

Gender: Customer's gender.

Partner, Dependents, Senior_Citizen: Demographic information.

Call_Duration, Data_Usage: Usage metrics.

Plan_Type, Plan_Level: Subscription details.

Monthly_Bill_Amount: Customer's monthly billing amount.

Tenure_Months: Duration of customer subscription.

Multiple_Lines, Tech_Support: Service features.

Churn: Whether the customer has churned (1) or is still active (0).

SQL Workflow

##Data Cleaning:

Queries to identify duplicates and null values.

EDA Highlights:

Count of active and churned users.

Breakdown of users by subscription level.

Average monthly bill amount across different tenure groups.

Insights Generation:

Predicting churn based on plan type, tenure, and monthly bill amount.

Analyzing the impact of technical support on customer retention.

Key Findings

The analysis uncovers:

Churn Patterns:

Higher churn rates among users with lower plan levels or shorter tenures.

Technical support availability positively correlates with retention.

Customer Lifetime Value:

Long-tenure customers contribute significantly to revenue.

Monthly bill amounts and service usage are key drivers of value.

Conclusion

This project highlights actionable insights for improving customer retention and maximizing lifetime value. Future steps could include building predictive models for churn and optimizing pricing strategies based on customer segments.
