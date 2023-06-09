#customer churn anlaysis

library(plyr)
library(corrplot)
library(ggplot2)
library(gridExtra)
library(ggthemes)
library(MASS)
library(randomForest)
library(party)
library(caret)

file.choose()
churn <- read.csv('/Users/nicholas/Desktop/CSUMB/Spring 23/BUS421/04 machine learning/excercise/Churn.csv')
str(churn)

#use sapply to check the number if missing values in each columns

sapply(churn, function(x) sum(is.na(x)))

# delete missing values
churn <- churn[complete.cases(churn), ]

# change “No internet service” and  to “No” for the following 6 features

# OnlineSecurity
# OnlineBackup
# DeviceProtection
# TechSupport
# streamingTV
# streamingMovies

cols_recode1 <- c(10:15)
for(i in 1:ncol(churn[,cols_recode1])) {
  churn[,cols_recode1][,i] <- as.factor(mapvalues
                                        (churn[,cols_recode1][,i], from =c("No internet service"),to=c("No")))
}


# change “No phone service” to “No” for column “MultipleLines”

churn$MultipleLines <- as.factor(mapvalues(churn$MultipleLines, 
                                           from=c("No phone service"),
                                           to=c("No")))

# Since the minimum tenure is 1 month and maximum tenure is 72 months, we can group them into five tenure groups:
#   
#   “0–12 Month”
# “12–24 Month”
# “24–48 Months”
# “48–60 Month”
# “> 60 Month”

min(churn$tenure); max(churn$tenure)

group_tenure <- function(tenure){
  if (tenure >= 0 & tenure <= 12){
    return('0-12 Month')
  }else if(tenure > 12 & tenure <= 24){
    return('12-24 Month')
  }else if (tenure > 24 & tenure <= 48){
    return('24-48 Month')
  }else if (tenure > 48 & tenure <=60){
    return('48-60 Month')
  }else if (tenure > 60){
    return('> 60 Month')
  }
}

churn$tenure_group <- sapply(churn$tenure,group_tenure)
churn$tenure_group <- as.factor(churn$tenure_group)              #convert to factor


#Change the values in column “SeniorCitizen” from 0 or 1 to “No” or “Yes”.
churn$SeniorCitizen <- as.factor(mapvalues(churn$SeniorCitizen,
                                           from=c("0","1"),
                                           to=c("No", "Yes")))

#change character features to factors
churn$Churn <- as.factor(churn$Churn)
churn$gender <- as.factor(churn$gender)
churn$Partner <- as.factor(churn$Partner)
churn$Dependents <- as.factor(churn$Dependents)
churn$PhoneService <- as.factor(churn$PhoneService)
churn$InternetService <- as.factor(churn$InternetService)

churn$Contract <- as.factor(churn$Contract)
churn$PaperlessBilling <- as.factor(churn$PaperlessBilling)
churn$PaymentMethod <- as.factor(churn$PaymentMethod)


### split train test set 70% train 30% test

intrain<- createDataPartition(churn$Churn,p=0.7,list=FALSE)
set.seed(2017)
training<- churn[intrain,]
testing<- churn[-intrain,]
str(training)

#build a tentative simple tree
tree <- ctree(Churn~Contract+tenure_group+PaperlessBilling, training)
plot(tree)

pred_tree <- predict(tree, testing)
print("Confusion Matrix for Decision Tree"); 
table(Predicted = pred_tree, Actual = testing$Churn)

# calculate the decision tree acuracy

p1 <- predict(tree, training)
tab1 <- table(Predicted = p1, Actual = training$Churn)
tab2 <- table(Predicted = pred_tree, Actual = testing$Churn)
print(paste('Decision Tree Accuracy',sum(diag(tab2))/sum(tab2)))

#Decision tree with Top 5 determining factors for customer churn
tree_5 <- ctree(Churn~TotalCharges+MonthlyCharges+tenure+Contract+PaymentMethod, 
                training)
plot(tree_5)

controls = ctree_control(maxdepth = 5)


## random forest
rfModel <- randomForest(Churn ~., data = training, ntree=200)
print(rfModel)

#tuning RF by adjusting number of trees
rfModel2 <- randomForest(Churn ~., data = training, ntree=1000)
print(rfModel2)

varImpPlot(rfModel, sort=T, n.var = 10, main = 'Top 10 Feature Importance')








