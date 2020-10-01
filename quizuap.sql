-- nomor 1
SELECT CustomerName, CustomerEmail ,[Total Price]=sum(ProductPrice*Quantity)
	from Customer c join HeaderTransaction ht on c.CustomerId=ht.CustomerId
	join DetailTransaction dt on ht.TransactionId=dt.TransactionId
	join Product p on dt.ProductId=p.ProductId
	where DATEDIFF(year,CustomerDOB,'2020/05/03')>23
	group by CustomerName, CustomerEmail
	having sum(ProductPrice*Quantity) > 35000000


-- nomor 2

select top 3 ProductName, Total=sum(ProductPrice*Quantity)
	from Product p join DetailTransaction dt on p.ProductId=dt.ProductId
	join ProductType pt on p.ProductTypeId=pt.ProductTypeId
	where ProductTypeName='Watches' 
	group by ProductName
UNION
	select * from(select top 3 ProductName,Total=sum(ProductPrice*Quantity)
	from Product p join DetailTransaction dt on p.ProductId=dt.ProductId
	join ProductType pt on p.ProductTypeId=pt.ProductTypeId 
	where ProductTypeName='Jewelry'
	group by ProductName
	order by Total Desc) a
	order by ProductName

-- nomor 3
select ProductName,ProductTypeName,ProductPrice
from Product p join ProductType pt on p.ProductTypeId=pt.ProductTypeId
join DetailTransaction dt on p.ProductId=dt.ProductId
where Quantity>3 
and ProductTypeName in ('Jewelry') and ProductName LIKE'%Earrings'


--nomor 4
create VIEW CustomerData as
select CustomerName,CustomerDOB,CustomerGender,CustomerEmail
from Customer
where CustomerEmail LIKE'%gmail.com' and datediff(year,CustomerDOB,'2020/01/01') >=25

select * from CustomerData

--nomor 5
create view LastThreeMonthsTransaction as
select TransactionDate, [Total Income]=sum(ProductPrice*Quantity)
from HeaderTransaction ht join DetailTransaction dt on ht.TransactionId=dt.TransactionId
join Product p on p.ProductId=dt.ProductId
where datediff(month,TransactionDate,'2020/04/28')<3
group by TransactionDate
having sum(ProductPrice*Quantity) >10000000

select * from LastThreeMonthsTransaction

-- nomor 6 

select [ID]=replace(ht.TransactionId,'TA','Transaction '), TransactionDate,CustomerName
 s from DetailTransaction dt join HeaderTransaction ht on dt.TransactionId=ht.TransactionId
join Customer c on ht.CustomerId=c.CustomerId join Staff s on ht.StaffId=s.StaffId,
(select [Average]=avg(StaffSalary) from Staff) as a
where s.StaffSalary<a.Average
group by TransactionDate,CustomerName,ht.TransactionId
having datepart(day,TransactionDate)=5 


-- nomor 7
create procedure ViewMonthlyReport @Month nvarchar(15) as
select TransactionDate, [Total Income]=sum(ProductPrice*Quantity),
[Total Transaction]=count(ht.TransactionId), [Average Income]=avg(ProductPrice*Quantity)
from DetailTransaction dt join Product p on dt.ProductId=p.ProductId
join HeaderTransaction ht on dt.TransactionId=ht.TransactionId
where datename(month,TransactionDate)=@Month
group by TransactionDate

exec ViewMonthlyReport 'January'

-- nomor 8
create procedure UpdateStock @ProductId nvarchar(6), @stock int as
	if exists(select ProductId from Product where ProductId=@ProductId)
	begin
		update Product set ProductStock=ProductStock+@stock
		where ProductId=@ProductId
		if (@@ROWCOUNT>0)
		begin
			print('Selected product''s stock has been updated.')
		end
	end
	else
	begin
		print('Product doesn''t exists.')
	end


--exec
exec UpdateStock 'PD020',2
-- lihat hasil
select * from Product
--nomor 9

create procedure TransactionReport @TransactionId varchar(10)as
declare @TransactionDate date, @CustomerName varchar(50),
	@ProductName varchar(50), @Quantity int, @ProductTypeName varchar(30),
	@ProductPrice int, @TotalPrice int, @TotalTransaction int
	, @TotalSales int;
declare cursor_transaction cursor
for select TransactionDate,CustomerName,ProductName,Quantity,ProductTypeName,
ProductPrice,[Total Price]=(ProductPrice*Quantity),[Total Transaction]=
count(ht.TransactionId)
from HeaderTransaction ht join DetailTransaction dt on ht.TransactionId=dt.TransactionId
join Product p on dt.ProductId=p.ProductId
join ProductType pt on p.ProductTypeId=pt.ProductTypeId
join Customer c on c.CustomerId=ht.CustomerId
where ht.TransactionId=@TransactionId
group by TransactionDate,CustomerName,ProductName,Quantity,ProductTypeName
,ProductPrice
order by ProductPrice

open cursor_transaction;
set @TotalSales=0
set @TotalTransaction=0
fetch next from cursor_transaction into
	@TransactionDate, @CustomerName,
	@ProductName, @Quantity, @ProductTypeName,
	@ProductPrice, @TotalPrice, @TotalTransaction;
	
	print('Transaction Report');
	print('------------------');
	print('Transaction Date		: '+ cast(@TransactionDate as varchar));
	print('Customer				: '+@CustomerName)
	print(' ')
while @@FETCH_STATUS=0
	begin
		print('Product Name			: '+@ProductName+' ('+cast(@Quantity as varchar)+'pcs)')
		print('Product Type Name		: '+@ProductTypeName)
		print('Product Price			: '+cast(@ProductPrice as varchar))
		print('')
		print('Total Price	:Rp. '+cast(@TotalPrice as varchar))
		print('--------------------------------------')
		set @TotalSales=@TotalPrice+@TotalSales
		set @TotalTransaction=@TotalTransaction+1
		fetch next from cursor_transaction into
	@TransactionDate, @CustomerName,
	@ProductName, @Quantity, @ProductTypeName,
	@ProductPrice, @TotalPrice, @TotalTransaction;
	end;

close cursor_transaction;

deallocate cursor_transaction
print('Total Transaction		: '+cast(@TotalTransaction as varchar))
print('Total Sales				: Rp. '+cast(@TotalSales as varchar))

exec TransactionReport 'TA007'

drop procedure TransactionReport




-- nomor 10
create trigger BackupDeletedProduct
on Product
after delete
as
begin
	create table BackupProduct(
	ProductId CHAR(5) PRIMARY KEY CHECK(ProductId LIKE 'PD[0-9][0-9][0-9]'),
	ProductTypeId CHAR(5) FOREIGN KEY REFERENCES ProductType(ProductTypeId) ON UPDATE CASCADE ON DELETE CASCADE,
	ProductName VARCHAR(30) NOT NULL,
	ProductPrice FLOAT NOT NULL,
	ProductStock INT NOT NULL
	)
	insert into BackupProduct select * from deleted 
end

--proses untuk metrigger
delete product where ProductId='PD001'
--lihat hasil
select * from Product

select * from BackupProduct