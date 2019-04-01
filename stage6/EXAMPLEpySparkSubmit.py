#Run With : spark-submit --packages org.apache.hadoop:hadoop-aws:2.7.1 --master spark://52.11.208.189:7077  pySparkSubmit.py
#Credit : https://www.cloudera.com/documentation/enterprise/5-14-x/topics/spark_s3.html

from pyspark import SparkContext
sc =SparkContext()


sonnets = sc.textFile("s3a://s3-to-ec2/sonnets.txt")
counts = sonnets.flatMap(lambda line: line.split(" ")).map(lambda word: (word, 1)).reduceByKey(lambda v1,v2: v1 + v2)
counts.saveAsTextFile("s3a://s3-to-ec2/output")
